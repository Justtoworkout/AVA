// backend/api/vapiWebhook.js
// Direct Firestore REST API Webhook — zero dependencies, zero auth overhead

const FIRESTORE_URL =
  'https://firestore.googleapis.com/v1/projects/gamma-86108/databases/(default)/documents/calls';

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

  try {
    const body = req.body || {};
    const msg = body.message ?? body;

    if (msg.type !== 'end-of-call-report') {
      return res.status(200).json({ status: 'ignored', type: msg.type });
    }

    const call = msg.call ?? {};
    const analysis = msg.analysis ?? {};

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
      timestamp: endedAt,
      durationSeconds,
      outcome,
      transcript: msg.transcript ?? '',
      recordingUrl: msg.recordingUrl ?? null,
      summary: msg.summary ?? null,
      vapiCallId: call.id ?? null,
    };

    const docId = call.id ?? `call_${Date.now()}`;
    const fields = Object.fromEntries(
      Object.entries(record).map(([k, v]) => [k, toFV(v)])
    );

    const firestoreRes = await fetch(`${FIRESTORE_URL}/${docId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ fields }),
    });

    if (!firestoreRes.ok) {
      const errText = await firestoreRes.text();
      console.error('[Error] Firestore REST write failed:', firestoreRes.status, errText);
      return res
        .status(500)
        .json({ error: `Firestore write failed (${firestoreRes.status}): ${errText}` });
    }

    console.log(`[Success] Call record written: ${docId}`);
    return res.status(200).json({ status: 'ok', id: docId });
  } catch (err) {
    console.error('[Error] Webhook exception:', err.message);
    return res.status(500).json({ error: err.message });
  }
};

function deriveOutcome(successEvaluation, endedReason) {
  if (endedReason === 'transfer') return 'transferred';
  if (endedReason === 'pipeline-error' || endedReason === 'error') return 'failed';
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
