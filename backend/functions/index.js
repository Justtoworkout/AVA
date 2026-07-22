// backend/functions/index.js
// Phase 1: Vapi end-of-call webhook → Firestore `calls` collection

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

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

  try {
    const body = req.body;

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
    functions.logger.error('vapiWebhook error', err);
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
