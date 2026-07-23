// backend/api/vapiWebhook.js
// Vercel serverless function — hardened version using Firebase Admin SDK and raw body verification

const crypto = require('crypto');
const admin  = require('firebase-admin');

// Initialize Firebase Admin once across serverless hot instances
if (admin.apps.length === 0) {
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    } else {
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID || 'gamma-86108',
      });
    }
  } catch (err) {
    console.error('Firebase initialization error:', err.message);
  }
}

const db = admin.firestore();

// Helper to read raw request stream body
function getRawBody(req) {
  return new Promise((resolve, reject) => {
    let body = [];
    req.on('data', (chunk) => {
      body.push(chunk);
    }).on('end', () => {
      resolve(Buffer.concat(body));
    }).on('error', (err) => {
      reject(err);
    });
  });
}

// ─── Input validation ─────────────────────────────────────────────────────────
function validatePayload(body) {
  if (!body || typeof body !== 'object') return false;
  const msg = body.message ?? body;
  return typeof msg.type === 'string';
}

// ─── Webhook signature verification on RAW request bytes (resolves serialization mismatches) ───
function verifySignature(rawBody, headers) {
  const secret = process.env.VAPI_WEBHOOK_SECRET;
  if (!secret) {
    console.warn('[WARN] VAPI_WEBHOOK_SECRET not set — skipping signature check (dev mode)');
    return true; 
  }

  const signature = headers['x-vapi-signature'] || headers['x-vapi-signature-256'];
  if (!signature) {
    console.error('[Error] Signature check failed: Missing x-vapi-signature header');
    return false;
  }

  try {
    const computed = crypto
      .createHmac('sha256', secret)
      .update(rawBody)
      .digest('hex');

    const sigBuffer  = Buffer.from(signature.replace('sha256=', ''), 'hex');
    const calcBuffer = Buffer.from(computed, 'hex');

    if (sigBuffer.length !== calcBuffer.length) {
      console.error('[Error] Signature check failed: Length mismatch');
      return false;
    }
    const verified = crypto.timingSafeEqual(sigBuffer, calcBuffer);
    if (!verified) {
      console.error('[Error] Signature check failed: Content mismatch');
    }
    return verified;
  } catch (err) {
    console.error('[Error] Signature verification exception:', err.message);
    return false;
  }
}

const handler = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Read raw body stream
    const rawBodyBuffer = await getRawBody(req);
    const rawBody = rawBodyBuffer.toString('utf8');

    // Signature verification on raw payload string bytes
    if (!verifySignature(rawBody, req.headers)) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Parse body manually since Vercel bodyParser is disabled
    let body = {};
    if (rawBody) {
      try {
        body = JSON.parse(rawBody);
      } catch (err) {
        return res.status(400).json({ error: 'Invalid JSON payload' });
      }
    }

    // Input validation
    if (!validatePayload(body)) {
      return res.status(400).json({ error: 'Invalid payload' });
    }

    const msg = body.message ?? body;

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
      timestamp: admin.firestore.Timestamp.fromDate(endedAt),
      durationSeconds,
      outcome,
      transcript,
      recordingUrl: typeof msg.recordingUrl === 'string' ? msg.recordingUrl : null,
      summary: summary || null,
      vapiCallId: typeof call.id === 'string' ? call.id : null,
    };

    const docId = typeof call.id === 'string' ? call.id : `call_${Date.now()}`;

    // Perform database write using official admin SDK
    await db.collection('calls').doc(docId).set(record, { merge: true });

    console.log(`[Success] Call record written: ${docId} outcome=${outcome}`);
    return res.status(200).json({ status: 'ok', id: docId, outcome });
  } catch (err) {
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

module.exports = handler;
module.exports.config = {
  api: {
    bodyParser: false, // Disables automatic parsing to allow raw stream verification
  },
};
