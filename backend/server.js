// backend/server.js
// Standalone webhook server for Render.com

const express  = require('express');
const admin    = require('firebase-admin');
const crypto   = require('crypto');
const rateLimit = require('express-rate-limit');
const helmet   = require('helmet');
const morgan   = require('morgan');

const app = express();

// ─── Security Middleware ──────────────────────────────────────────────────────

// 1. Security headers (X-Frame-Options, CSP, HSTS, etc.)
app.use(helmet());

// 2. Structured request logging (no sensitive body fields logged)
app.use(morgan('combined'));

// 3. Body parser — limit payload to 1MB to prevent DoS
app.use(express.json({ limit: '1mb' }));

// 4. Rate limiting — max 200 requests per minute per IP
const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
});
app.use('/vapiWebhook', limiter);

// ─── Firebase Admin Initialisation (via env var, NOT file) ───────────────────
// Set GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_SERVICE_ACCOUNT_JSON in
// your Render / deployment platform's environment variables — never commit keys.
let db;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    // Render / Vercel: paste the JSON string as an env variable
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    // Google Cloud / ADC path
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  } else if (process.env.NODE_ENV === 'test' || process.env.CI) {
    // CI/Test mode: prevent default credentials crash by using a mock credential config
    console.log('[INFO] CI/Test environment detected — using mock Firebase Admin credentials');
    admin.initializeApp({
      projectId: 'gamma-86108',
      credential: {
        getAccessToken: () => Promise.resolve({ access_token: 'mock-token', expires_in: 3600 })
      }
    });
  } else {
    console.warn('[WARN] No Firebase credentials found. Firestore writes will fail.');
    admin.initializeApp();
  }
  db = admin.firestore();
} catch (err) {
  console.error('[FATAL] Firebase init failed:', err.message);
  process.exit(1);
}

// ─── Webhook Signature Verification Middleware ────────────────────────────────
// Vapi signs requests with HMAC-SHA256. Set VAPI_WEBHOOK_SECRET in env vars.
function verifyVapiSignature(req, res, next) {
  const secret = process.env.VAPI_WEBHOOK_SECRET;

  // If no secret is configured, skip verification (dev mode only)
  if (!secret) {
    console.warn('[WARN] VAPI_WEBHOOK_SECRET not set — skipping signature check (dev mode)');
    return next();
  }

  const signature = req.headers['x-vapi-signature'] || req.headers['x-vapi-signature-256'];
  if (!signature) {
    return res.status(401).json({ error: 'Missing webhook signature' });
  }

  try {
    const rawBody  = JSON.stringify(req.body);
    const computed = crypto
      .createHmac('sha256', secret)
      .update(rawBody)
      .digest('hex');

    // Constant-time comparison to prevent timing attacks
    const sigBuffer  = Buffer.from(signature.replace('sha256=', ''), 'hex');
    const calcBuffer = Buffer.from(computed, 'hex');

    if (sigBuffer.length !== calcBuffer.length ||
        !crypto.timingSafeEqual(sigBuffer, calcBuffer)) {
      return res.status(401).json({ error: 'Invalid webhook signature' });
    }
  } catch {
    return res.status(401).json({ error: 'Signature verification failed' });
  }

  next();
}

// ─── Input Validation ─────────────────────────────────────────────────────────
function validateWebhookPayload(body) {
  if (!body || typeof body !== 'object') return false;
  const msg = body.message ?? body;
  if (typeof msg.type !== 'string') return false;
  return true;
}

// ─── Routes ───────────────────────────────────────────────────────────────────

// Health Check — generic 200, no server details exposed
app.get('/', (_req, res) => res.status(200).json({ status: 'ok' }));

// Vapi webhook endpoint
app.post('/vapiWebhook', verifyVapiSignature, (req, res) => {
  // Input validation
  if (!validateWebhookPayload(req.body)) {
    return res.status(400).json({ error: 'Invalid payload' });
  }

  const body = req.body;
  const msg  = body.message ?? body;

  // Respond immediately to prevent Vapi timeouts
  res.status(200).json({ status: 'received' });

  if (msg.type !== 'end-of-call-report') return;

  // Fire-and-forget background write
  (async () => {
    try {
      const call     = msg.call ?? {};
      const analysis = msg.analysis ?? {};

      const outcome = deriveOutcome(
        analysis.successEvaluation,
        call.endedReason ?? msg.endedReason
      );

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
        transcript:   typeof msg.transcript   === 'string' ? msg.transcript   : '',
        recordingUrl: typeof msg.recordingUrl  === 'string' ? msg.recordingUrl : null,
        summary:      typeof msg.summary       === 'string' ? msg.summary      : null,
        vapiCallId:   typeof call.id           === 'string' ? call.id          : null,
      };

      const docRef = call.id
        ? db.collection('calls').doc(call.id)
        : db.collection('calls').doc();

      await docRef.set(record, { merge: true });
      console.log(`[Success] Written call ${docRef.id} outcome=${outcome}`);
    } catch (err) {
      // Generic log — do NOT expose internal error details externally
      console.error('[Error] Background database write failed:', err.message);
    }
  })();
});

// ─── 404 & Global Error Handler ───────────────────────────────────────────────
app.use((_req, res) => res.status(404).json({ error: 'Not found' }));

app.use((err, _req, res, _next) => {
  console.error('[Error] Unhandled:', err.message);
  // Generic message only — never expose stack traces
  res.status(500).json({ error: 'Internal server error' });
});

// ─── Helper ───────────────────────────────────────────────────────────────────
function deriveOutcome(successEvaluation, endedReason) {
  if (endedReason === 'transfer') return 'transferred';
  if (endedReason === 'pipeline-error' || endedReason === 'error') return 'failed';

  switch (successEvaluation) {
    case 'true':
    case true:  return 'booked';
    case 'false':
    case false: return 'failed';
    default:    return 'completed';
  }
}

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
