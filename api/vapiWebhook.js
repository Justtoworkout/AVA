// api/vapiWebhook.js
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
    const artifact = msg.artifact ?? {};
    const summary = msg.summary ?? analysis.summary ?? artifact.summary ?? '';
    const transcript = msg.transcript ?? artifact.transcript ?? '';
    const structuredData = msg.structuredData ?? analysis.structuredData ?? artifact.structuredData ?? {};

    const outcome = deriveOutcome(
      analysis,
      call.endedReason ?? msg.endedReason,
      summary,
      transcript,
      structuredData
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
      transcript,
      recordingUrl: msg.recordingUrl ?? artifact.recordingUrl ?? null,
      summary: summary || null,
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

    console.log(`[Success] Call record written: ${docId} (outcome=${outcome})`);
    return res.status(200).json({ status: 'ok', id: docId, outcome });
  } catch (err) {
    console.error('[Error] Webhook exception:', err.message);
    return res.status(500).json({ error: err.message });
  }
};

function deriveOutcome(analysis, endedReason, summary, transcript, structuredData) {
  if (endedReason === 'transfer') return 'transferred';
  if (endedReason === 'pipeline-error' || endedReason === 'error') return 'failed';

  const successEval = analysis?.successEvaluation;
  if (successEval === 'true' || successEval === true || successEval === 'TRUE') {
    return 'booked';
  }
  if (successEval === 'false' || successEval === false || successEval === 'FALSE') {
    return 'failed';
  }

  // Check structured data if Vapi passes custom structured outputs
  if (
    structuredData?.appointmentBooked === true ||
    structuredData?.booked === true ||
    structuredData?.status === 'booked'
  ) {
    return 'booked';
  }

  // Fallback: Check summary & transcript text for appointment/booking indicators
  const text = `${summary || ''} ${transcript || ''}`.toLowerCase();
  if (
    text.includes('booked') ||
    text.includes('appointment scheduled') ||
    text.includes('appointment booked') ||
    text.includes('appointment confirmed') ||
    text.includes('scheduled for') ||
    text.includes('scheduled an appointment') ||
    text.includes('schedule an appointment') ||
    text.includes('book an appointment') ||
    text.includes('slot confirmed') ||
    text.includes('dr.') ||
    text.includes('doctor')
  ) {
    return 'booked';
  }

  return 'completed';
}
