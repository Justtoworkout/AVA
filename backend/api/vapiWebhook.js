// backend/api/vapiWebhook.js
// Pure REST approach — no firebase-admin, no gRPC, no SDK auth issues.
// Uses Node.js built-in crypto + fetch to talk directly to Firestore REST API.

const crypto = require('crypto');

// ─── Service Account (inlined) ───────────────────────────────────────────────
const SA = {
  project_id: 'gamma-86108',
  client_email: 'firebase-adminsdk-fbsvc@gamma-86108.iam.gserviceaccount.com',
  private_key: `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDIqnEgVFaaZAdX
rgih6eO0okg72fkFbbX+QAimGE1ge3954jcHuAl8dt1OjOy3Xrr0ORovCsNAFN9C
Cv/erH7+d6S3wisJl+OY50S9TvlTyhLYPxmEmwhqf56J0DXQo1vUf9hIOHh71+zG
mOHQJX4PFFv9Ztr5Q/hvbELgwMecpXdNZwkuzmI8BPqWISPbMC0yKxKIQukqqPeG
rR2P77UVEDCALgIEisF09fV+LsCWx3R14VC1VTziSt65zmeeMCIh/h0LDYibs6uO
lWzyjlsEqpyQoCNUK3Us59we+MuaZ6X6AX/e/TUb46/TeSSHRcTJ610ZfwvSRDUx
WQbsXVLFAgMBAAECggEABqCeeN9gNtwr4+jzDwnvA9XCRfvGfjfn5VxPDNFLqO6b
QLbIc4BQC+TPHVuJK+s8iHlkVH5qAXFPCFrdpYiT7yqbbZhDnJ8AHNoyioATuwE3
Cx5WZOtL5VyOq2WNiXUDwOpyBbybuhdhEhQVjS7X0X6uJRnjDI2CpIdyVAL59MHx
TFuDfyA7hpPBF9DzuzpE9q3HLe2lA07vsAR6mN6IT4ipMI8fPcsjMWWPPeItHNvo
RyI5G2Ztc14f0wvSYy+W9diuHvZaHzJlGI4JLIjSVMwF6f5SSKvmfPP9XDwXVyLN
5CTULbwIwPON4AT8hQkuOlf8V8LKfXqsarNuo9YcMQKBgQDlETIlgjTPDmHPtVCF
yt4CYVA5UCYp86+z+dscZzhCwhHEBK0JgpSP4MKg8CRJUYkDFQGSHRAavYJlbuOI
d31JC1CNRik8UvWHeiNhnq2dp/4mMVw3pbUNW/NLh8ZOPBZUhtr9KDsXp2decnTR
9X5YleCdFuTN844WPfzNNvzqKQKBgQDgQmEFqTO5hVy3YIsgfyRQbrg2KBtz8Kq7
Tlpb1SRamlC298VbCc/Bv6K567jbzDCl4uoBdo7z7Grl2KY4+llqv43PNIs6p+QD
NMb+5phQXDfDEdQPwV1A+y5c4RBb/SPW3eyUCISskOTFzyUFKF/2ZsFmNmPOi0BG
aMNgpbwvPQKBgQCe6Eb5blJkMX35MbcimZFZ5VhZ6hgPklWZbQNruM92wFrCuNux
dTzKcwmRzAXgNwftc20bh73cTwtegoal7P6k5YyD9OA2UPazfS9+US3v6NKOfD+U
+weWtOsawp33OAflq4fPh1E3H5K+GnigDsYPfinL0E358bPoCiiN1E+vwQKBgA46
Z+lyCMQWgAFqcKlJJ8aqn6lf9g3vEQX9PKJi7YGKFODm63CROMs0G2DsYbggRl3f
/bTGDt/O+iFHE5S93Xp2WMryrHq2ODMz4ARAIR3IHAmWUfwF6qK6zQA7j0wmzWVO
gzoJKFHCh6E9OT4Qh7YcYtzXSpHKJ/PPpcW1/jCJAoGAaD9MemLnCXfgYc7RJmgv
2G4ncNLsMC9A+zDQ3bKo9IRuXI5/F+dtPiAgXL92XKPTQdNoft2f5NCuuXFd6abn
51d5/bKMLeCWjc4+Ucf6suPQ6YSTWt3H8m78j4G3+B4GtSBajOMvMAoY9aHLUPn4
vWDBhTlpwlgI89wxa8OmRFk=
-----END PRIVATE KEY-----`,
};

const FIRESTORE_BASE =
  `https://firestore.googleapis.com/v1/projects/${SA.project_id}/databases/(default)/documents`;

// ─── OAuth2 token via JWT (RS256) ─────────────────────────────────────────────
async function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  const header  = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: SA.client_email,
    scope: 'https://www.googleapis.com/auth/datastore',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })).toString('base64url');

  const signer = crypto.createSign('RSA-SHA256');
  signer.update(`${header}.${payload}`);
  const sig = signer.sign(SA.private_key, 'base64url');
  const jwt = `${header}.${payload}.${sig}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Token fetch failed: ${res.status} ${txt}`);
  }
  const data = await res.json();
  return data.access_token;
}

// ─── Convert JS value → Firestore typed field ────────────────────────────────
function toFV(v) {
  if (v === null || v === undefined)  return { nullValue: null };
  if (typeof v === 'boolean')          return { booleanValue: v };
  if (typeof v === 'number')           return Number.isInteger(v)
    ? { integerValue: String(v) }
    : { doubleValue: v };
  if (v instanceof Date)               return { timestampValue: v.toISOString() };
  if (typeof v === 'string')           return { stringValue: v };
  if (typeof v === 'object')           return {
    mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, val]) => [k, toFV(val)])) }
  };
  return { stringValue: String(v) };
}

// ─── Write document via REST ──────────────────────────────────────────────────
async function firestoreSet(collection, docId, data) {
  const token  = await getAccessToken();
  const fields = Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toFV(v)]));
  const url    = `${FIRESTORE_BASE}/${collection}/${docId}`;

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Firestore PATCH failed: ${res.status} ${txt}`);
  }
  return res.json();
}

// ─── Vapi Webhook Handler ─────────────────────────────────────────────────────
module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const body = req.body;
    const msg  = body.message ?? body;

    if (msg.type !== 'end-of-call-report') {
      return res.status(200).json({ status: 'ignored', type: msg.type });
    }

    const call     = msg.call     ?? {};
    const analysis = msg.analysis ?? {};

    const outcome  = deriveOutcome(analysis.successEvaluation, call.endedReason ?? msg.endedReason);
    const startedAt = call.startedAt ? new Date(call.startedAt) : null;
    const endedAt   = call.endedAt   ? new Date(call.endedAt)   : new Date();
    const durationSeconds = startedAt ? Math.round((endedAt - startedAt) / 1000) : 0;

    const patientNumber =
      call.customer?.number ??
      call.phoneNumber?.number ??
      call.fromNumber ??
      'unknown';

    const record = {
      patientNumber,
      timestamp: endedAt,          // Date → timestampValue via toFV()
      durationSeconds,
      outcome,
      transcript:    msg.transcript    ?? '',
      recordingUrl:  msg.recordingUrl  ?? null,
      summary:       msg.summary       ?? null,
      vapiCallId:    call.id           ?? null,
    };

    const docId = call.id ?? `call_${Date.now()}`;
    await firestoreSet('calls', docId, record);
    console.log(`[Success] Written call ${docId} outcome=${outcome}`);

    return res.status(200).json({ status: 'ok', id: docId });
  } catch (err) {
    console.error('[Error] Webhook failed:', err.message);
    return res.status(500).json({ error: err.message });
  }
};

// ─── Outcome mapping ──────────────────────────────────────────────────────────
function deriveOutcome(successEvaluation, endedReason) {
  if (endedReason === 'transfer')                              return 'transferred';
  if (endedReason === 'pipeline-error' || endedReason === 'error') return 'failed';
  switch (successEvaluation) {
    case 'true':  case true:  return 'booked';
    case 'false': case false: return 'failed';
    default:                  return 'completed';
  }
}
