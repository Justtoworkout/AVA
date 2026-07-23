// backend/api/vapiWebhook.js
// Vercel serverless function — hardened version

const crypto = require('crypto');

const FIRESTORE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'gamma-86108';
const FIRESTORE_URL = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT_ID}/databases/(default)/documents/calls`;

// ─── Input validation ─────────────────────────────────────────────────────────
function validatePayload(body) {
  if (!body || typeof body !== 'object') return false;
  const msg = body.message ?? body;
  return typeof msg.type === 'string';
}

// ─── Webhook signature verification ──────────────────────────────────────────
function verifySignature(req) {
  const secret = process.env.VAPI_WEBHOOK_SECRET;
  if (!secret) return true; // Skip in dev if not configured

  const signature = req.headers['x-vapi-signature'] || req.headers['x-vapi-signature-256'];
  if (!signature) return false;

  try {
    const computed = crypto
      .createHmac('sha256', secret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    const sigBuffer  = Buffer.from(signature.replace('sha256=', ''), 'hex');
    const calcBuffer = Buffer.from(computed, 'hex');

    if (sigBuffer.length !== calcBuffer.length) return false;
    return crypto.timingSafeEqual(sigBuffer, calcBuffer);
  } catch {
    return false;
  }
}

function toFV(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number')
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'object') {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(v).map(([k, val]) => [k, toFV(val)])
        ),
      },
    };
  }
  return { stringValue: String(v) };
}

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Signature verification
  if (!verifySignature(req)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Input validation
  if (!validatePayload(req.body)) {
    return res.status(400).json({ error: 'Invalid payload' });
  }

  try {
    const body = req.body || {};
    const msg  = body.message ?? body;

    if (msg.type !== 'end-of-call-report') {
      return res.status(200).json({ status: 'ignored' });
    }

    const call     = msg.call ?? {};
    const analysis = msg.analysis ?? {};
    const artifact = msg.artifact ?? {};

    const summary    = typeof msg.summary    === 'string' ? msg.summary    :
                       typeof analysis.summary === 'string' ? analysis.summary : '';
    const transcript = typeof msg.transcript === 'string' ? msg.transcript :
                       typeof artifact.transcript === 'string' ? artifact.transcript : '';

    const structuredData = msg.structuredData ?? analysis.structuredData ?? {};

    const outcome = deriveOutcome(analysis, call.endedReason ?? msg.endedReason, summary, transcript, structuredData);

    const startedAt = call.startedAt ? new Date(call.startedAt) : null;
    const endedAt   = call.endedAt   ? new Date(call.endedAt)   : new Date();
    const durationSeconds = startedAt
      ? Math.round((endedAt - startedAt) / 1000)
      : 0;

    const patientNumber =
      call.customer?.number ??
      call.phoneNumber?.number ??
      call.fromNumber ??
      'unknown';

    const record = {
      patientNumber,
      timestamp: endedAt,
      durationSeconds,
      outcome,
      transcript,
      recordingUrl: typeof msg.recordingUrl === 'string' ? msg.recordingUrl : null,
      summary: summary || null,
      vapiCallId: typeof call.id === 'string' ? call.id : null,
    };

    const docId  = typeof call.id === 'string' ? call.id : `call_${Date.now()}`;
    const fields = Object.fromEntries(
      Object.entries(record).map(([k, v]) => [k, toFV(v)])
    );

    // Use env var for project ID — not hardcoded (fixes M-004)
    const firestoreRes = await fetch(`${FIRESTORE_URL}/${docId}`, {
      method:  'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ fields }),
    });

    if (!firestoreRes.ok) {
      // Generic error response — no internal details leaked (fixes M-001)
      console.error('[Error] Firestore write failed:', firestoreRes.status);
      return res.status(500).json({ error: 'Database write failed' });
    }

    console.log(`[Success] Call record written: ${docId} outcome=${outcome}`);
    return res.status(200).json({ status: 'ok', id: docId, outcome });
  } catch (err) {
    // Generic message only — no stack trace (fixes M-001)
    console.error('[Error] Webhook exception:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

function deriveOutcome(analysis, endedReason, summary, transcript, structuredData) {
  if (endedReason === 'transfer') return 'transferred';
  if (endedReason === 'pipeline-error' || endedReason === 'error') return 'failed';

  const successEval = analysis?.successEvaluation;
  if (successEval === 'true'  || successEval === true  || successEval === 'TRUE')  return 'booked';
  if (successEval === 'false' || successEval === false || successEval === 'FALSE') return 'failed';

  if (structuredData?.appointmentBooked === true ||
      structuredData?.booked === true ||
      structuredData?.status === 'booked') {
    return 'booked';
  }

  const text = `${summary || ''} ${transcript || ''}`.toLowerCase();
  if (text.includes('booked') ||
      text.includes('appointment scheduled') ||
      text.includes('appointment confirmed') ||
      text.includes('scheduled for')) {
    return 'booked';
  }

  return 'completed';
}
