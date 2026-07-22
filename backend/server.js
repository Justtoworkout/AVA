// backend/server.js
// Standalone webhook server for Render.com (Bypasses Blaze requirement)

const express = require('express');
const admin = require('firebase-admin');
const path = require('path');

const app = express();
app.use(express.json());

// Initialize Firebase Admin SDK using service-account.json
const serviceAccount = require(path.join(__dirname, 'service-account.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Health Check
app.get('/', (req, res) => {
  res.status(200).send('AVA Webhook Server Status: Live');
});

// Vapi webhook endpoint
app.post('/vapiWebhook', (req, res) => {
  const body = req.body;
  const msg = body.message ?? body;

  // 1. Respond to Vapi immediately to prevent timeouts
  res.status(200).json({ status: 'received' });

  // 2. Process the database write asynchronously in the background
  if (msg.type !== 'end-of-call-report') {
    return;
  }

  // Fire-and-forget background process
  (async () => {
    try {
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

      await docRef.set(record, { merge: true });
      console.log(`[Success] Written call ${docRef.id} with outcome: ${outcome} (Background process)`);
    } catch (err) {
      console.error('[Error] Background database write failed:', err);
    }
  })();
});

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

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
