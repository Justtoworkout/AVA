// backend/functions/index.js
// Phase 1: Vapi end-of-call webhook → Firestore `calls` collection

const functions = require('firebase-functions');
const admin    = require('firebase-admin');
const crypto   = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// ─── Webhook Signature Verification ──────────────────────────────────────────
function verifySignature(req) {
  const secret = process.env.VAPI_WEBHOOK_SECRET;
  if (!secret) return true; // Dev mode: skip if not configured

  const signature = req.headers['x-vapi-signature'] || req.headers['x-vapi-signature-256'];
  if (!signature) return false;

  try {
    const computed = crypto
      .createHmac('sha256', secret)
      .update(JSON.stringify(req.body))
      .digest('hex');
    const sigBuf  = Buffer.from(signature.replace('sha256=', ''), 'hex');
    const calcBuf = Buffer.from(computed, 'hex');
    if (sigBuf.length !== calcBuf.length) return false;
    return crypto.timingSafeEqual(sigBuf, calcBuf);
  } catch {
    return false;
  }
}

/**
 * POST /vapiWebhook
 * Vapi sends end-of-call-report with this shape (relevant fields):
 * {
 *   message: {
 *     type: "end-of-call-report",
 *     call: { id, phoneNumber: { number }, startedAt, endedAt },
 *     transcript: "...",
 *     recordingUrl: "...",
 *     summary: "...",
 *     analysis: { successEvaluation: "true"|"false"|"unknown" }
 *   }
 * }
 */
exports.vapiWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Verify webhook signature
  if (!verifySignature(req)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Input validation
  const body = req.body;
  if (!body || typeof body !== 'object' || typeof (body.message ?? body).type !== 'string') {
    return res.status(400).json({ error: 'Invalid payload' });
  }

  try {

    // Vapi wraps everything in a `message` envelope
    const msg = body.message ?? body;

    // Only process end-of-call reports
    if (msg.type !== 'end-of-call-report') {
      return res.status(200).json({ status: 'ignored', type: msg.type });
    }

    const call = msg.call ?? {};
    const analysis = msg.analysis ?? {};

    // Derive outcome from successEvaluation + endedReason
    const outcome = deriveOutcome(
      analysis.successEvaluation,
      call.endedReason ?? msg.endedReason
    );

    // Calculate duration
    const startedAt = call.startedAt ? new Date(call.startedAt) : null;
    const endedAt = call.endedAt ? new Date(call.endedAt) : new Date();
    const durationSeconds = startedAt
      ? Math.round((endedAt - startedAt) / 1000)
      : 0;

    // Patient number: from phoneNumberId or customer number
    const patientNumber =
      call.customer?.number ??
      call.phoneNumber?.number ??
      call.fromNumber ??
      'unknown';

    const record = {
      patientNumber,
      timestamp: admin.firestore.Timestamp.fromDate(endedAt),
      durationSeconds,
      outcome,
      transcript: msg.transcript ?? '',
      recordingUrl: msg.recordingUrl ?? null,
      summary: msg.summary ?? null,
      // Keep raw Vapi call ID for deduplication
      vapiCallId: call.id ?? null,
    };

    // Use vapiCallId as doc ID if available to prevent duplicate writes
    const docRef = call.id
      ? db.collection('calls').doc(call.id)
      : db.collection('calls').doc();

    await docRef.set(record, { merge: true });

    functions.logger.info('Call record written', { id: docRef.id, outcome });
    return res.status(200).json({ status: 'ok', id: docRef.id });
  } catch (err) {
    // Log full error server-side, return generic message to caller (fixes M-001)
    functions.logger.error('vapiWebhook error', { message: err.message });
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * Map Vapi's successEvaluation + endedReason to our outcome enum.
 * outcome: 'booked' | 'failed' | 'transferred' | 'completed'
 */
function deriveOutcome(successEvaluation, endedReason) {
  if (endedReason === 'transfer') return 'transferred';
  if (endedReason === 'pipeline-error' || endedReason === 'error')
    return 'failed';

  switch (successEvaluation) {
    case 'true':
    case true:
      return 'booked';
    case 'false':
    case false:
      return 'failed';
    default:
      return 'completed';
  }
}
