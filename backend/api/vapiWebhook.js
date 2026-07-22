// backend/api/vapiWebhook.js
// Vercel Serverless Function — zero cold starts

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK (Singleton pattern for Serverless)
if (admin.apps.length === 0) {
  const serviceAccount = require(path.join(__dirname, '..', 'service-account.json'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

// Force REST transport — Vercel free tier blocks gRPC (causes DEADLINE_EXCEEDED)
const db = admin.firestore();
db.settings({ preferRest: true });

module.exports = async (req, res) => {
  // Only handle POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const body = req.body;
    const msg = body.message ?? body;

    // Handle end-of-call report
    if (msg.type !== 'end-of-call-report') {
      return res.status(200).json({ status: 'ignored', type: msg.type });
    }

    const call = msg.call ?? {};
    const analysis = msg.analysis ?? {};

    // Map Vapi endedReason and successEvaluation to outcome
    const outcome = deriveOutcome(
      analysis.successEvaluation,
      call.endedReason ?? msg.endedReason
    );

    const startedAt = call.startedAt ? new Date(call.startedAt) : null;
    const endedAt = call.endedAt ? new Date(call.endedAt) : new Date();
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
      timestamp: admin.firestore.Timestamp.fromDate(endedAt),
      durationSeconds,
      outcome,
      transcript: msg.transcript ?? '',
      recordingUrl: msg.recordingUrl ?? null,
      summary: msg.summary ?? null,
      vapiCallId: call.id ?? null,
    };

    // Use vapiCallId as doc ID to prevent duplicate writes
    const docRef = call.id
      ? db.collection('calls').doc(call.id)
      : db.collection('calls').doc();

    // Await the write so Vercel does not terminate it early
    await docRef.set(record, { merge: true });
    console.log(`[Success] Written call ${docRef.id} with outcome: ${outcome}`);

    return res.status(200).json({ status: 'ok', id: docRef.id });
  } catch (err) {
    console.error('[Error] Vercel database write failed:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

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
