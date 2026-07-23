// load-tests/baseline-load-test.js
// ============================================================
// AVA Backend — Baseline / Load Test
// Tool: k6 (https://k6.io)
// Profile:
//   • 100 virtual users (VUs)
//   • Duration: 1 minute continuous
//   • Target: AVA webhook server (Express / Vercel / Firebase CF)
// ============================================================
//
// HOW TO RUN:
//   1. Install k6: https://k6.io/docs/getting-started/installation/
//      Windows: choco install k6  OR  winget install k6
//      Mac:     brew install k6
//      Linux:   sudo apt install k6
//   2. Start your backend server:
//      cd backend && node server.js
//   3. Run baseline test:
//      k6 run load-tests/baseline-load-test.js
//   4. Run with HTML report:
//      k6 run --out json=load-tests/results/baseline-results.json load-tests/baseline-load-test.js
// ============================================================

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ─── Custom Metrics ──────────────────────────────────────────────────────────
const errorRate       = new Rate('error_rate');
const webhookDuration = new Trend('webhook_response_time_ms');
const healthDuration  = new Trend('health_response_time_ms');
const successfulPosts = new Counter('successful_webhook_posts');

// ─── Load Test Configuration ─────────────────────────────────────────────────
export const options = {
  // Scenario: 100 VUs continuously for 60 seconds
  scenarios: {
    baseline_load: {
      executor: 'constant-vus',
      vus: 100,            // 100 virtual users at all times
      duration: '60s',     // Run for exactly 1 minute
    },
  },

  // Performance thresholds — test FAILS if these are breached
  thresholds: {
    // 95th percentile response time must stay under 2 seconds
    http_req_duration:         ['p(95)<2000'],
    // 99th percentile response time must stay under 5 seconds
    'http_req_duration{type:webhook}': ['p(99)<5000'],
    // Health check must always be fast
    'http_req_duration{type:health}':  ['p(95)<500'],
    // Error rate must stay below 5%
    http_req_failed:           ['rate<0.05'],
    error_rate:                ['rate<0.05'],
  },
};

// ─── Target Configuration ────────────────────────────────────────────────────
// Update BASE_URL to point to your running server:
//   Local:    http://localhost:8080
//   Render:   https://your-app.onrender.com
//   Vercel:   https://your-project.vercel.app
const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8080';

// ─── Sample Vapi Webhook Payloads ────────────────────────────────────────────
// Realistic payloads representing different call outcomes.
// k6 will cycle through these to simulate varied load.
const WEBHOOK_PAYLOADS = [
  // Payload 1: Booked appointment
  {
    message: {
      type: 'end-of-call-report',
      call: {
        id: `test-call-booked-${Date.now()}`,
        startedAt: new Date(Date.now() - 90000).toISOString(),
        endedAt: new Date().toISOString(),
        endedReason: 'customer-ended-call',
        customer: { number: '+11234567890' },
      },
      analysis: { successEvaluation: 'true' },
      transcript: 'Patient called to book an appointment. Appointment scheduled for next Monday.',
      summary: 'Appointment booked successfully for the patient.',
      recordingUrl: 'https://storage.vapi.ai/recordings/test-001.mp3',
    },
  },
  // Payload 2: Failed call
  {
    message: {
      type: 'end-of-call-report',
      call: {
        id: `test-call-failed-${Date.now()}`,
        startedAt: new Date(Date.now() - 30000).toISOString(),
        endedAt: new Date().toISOString(),
        endedReason: 'pipeline-error',
        customer: { number: '+19876543210' },
      },
      analysis: { successEvaluation: 'false' },
      transcript: '',
      summary: null,
      recordingUrl: null,
    },
  },
  // Payload 3: Transferred call
  {
    message: {
      type: 'end-of-call-report',
      call: {
        id: `test-call-transferred-${Date.now()}`,
        startedAt: new Date(Date.now() - 120000).toISOString(),
        endedAt: new Date().toISOString(),
        endedReason: 'transfer',
        customer: { number: '+15559876543' },
      },
      analysis: { successEvaluation: 'unknown' },
      transcript: 'Patient requested to speak with a human agent.',
      summary: 'Patient transferred to reception staff.',
      recordingUrl: 'https://storage.vapi.ai/recordings/test-003.mp3',
    },
  },
  // Payload 4: Completed but not booked
  {
    message: {
      type: 'end-of-call-report',
      call: {
        id: `test-call-completed-${Date.now()}`,
        startedAt: new Date(Date.now() - 60000).toISOString(),
        endedAt: new Date().toISOString(),
        endedReason: 'customer-ended-call',
        customer: { number: '+14151234567' },
      },
      analysis: { successEvaluation: 'false' },
      transcript: 'Patient called to inquire about services. No appointment was booked.',
      summary: 'General inquiry call. No appointment booked.',
      recordingUrl: null,
    },
  },
  // Payload 5: Non-target message type (should be ignored by server)
  {
    message: {
      type: 'status-update',
      call: { id: `test-status-${Date.now()}` },
    },
  },
];

// ─── Main VU Execution Function ──────────────────────────────────────────────
export default function () {
  const vuId = __VU;       // Virtual User ID (1–100)
  const iter = __ITER;     // Iteration count per VU

  // ── Request 1: Health Check (GET /) ────────────────────────────────────────
  // Every 5th iteration per VU, hit the health check endpoint
  if (iter % 5 === 0) {
    const healthRes = http.get(`${BASE_URL}/`, {
      tags: { type: 'health', endpoint: 'health_check' },
    });

    const healthOk = check(healthRes, {
      '✅ Health check returns 200':  (r) => r.status === 200,
      '✅ Health check under 500ms':  (r) => r.timings.duration < 500,
      '✅ Response body not empty':   (r) => r.body && r.body.length > 0,
    });

    healthDuration.add(healthRes.timings.duration);
    errorRate.add(!healthOk);
  }

  // ── Request 2: Webhook POST ─────────────────────────────────────────────────
  // Pick a payload from the pool, cycling by VU ID and iteration
  const payloadIndex = (vuId + iter) % WEBHOOK_PAYLOADS.length;
  const payload = JSON.parse(JSON.stringify(WEBHOOK_PAYLOADS[payloadIndex]));

  // Make the call ID unique per VU + iteration to avoid Firestore dedup merging
  if (payload.message?.call?.id) {
    payload.message.call.id = `${payload.message.call.id}-vu${vuId}-iter${iter}`;
  }

  const webhookRes = http.post(
    `${BASE_URL}/vapiWebhook`,
    JSON.stringify(payload),
    {
      headers: {
        'Content-Type': 'application/json',
        'Accept':        'application/json',
        'User-Agent':    `AVALoadTest/1.0 VU-${vuId}`,
      },
      tags: { type: 'webhook', endpoint: 'vapiWebhook' },
      timeout: '10s',
    }
  );

  // Assertions on the webhook response
  const webhookOk = check(webhookRes, {
    '✅ Webhook returns 200':            (r) => r.status === 200,
    '✅ Webhook not 5xx error':          (r) => r.status < 500,
    '✅ Webhook response time < 2000ms': (r) => r.timings.duration < 2000,
    '✅ Response is JSON':               (r) => {
      try { JSON.parse(r.body); return true; } catch { return false; }
    },
    '✅ Response has status field':      (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.status !== undefined;
      } catch { return false; }
    },
  });

  webhookDuration.add(webhookRes.timings.duration);
  errorRate.add(!webhookOk);

  if (webhookOk && webhookRes.status === 200) {
    successfulPosts.add(1);
  }

  // Brief pause to simulate realistic user think time (50–150ms)
  sleep(Math.random() * 0.1 + 0.05);
}

// ─── Setup: Runs once before load test starts ────────────────────────────────
export function setup() {
  console.log('='.repeat(60));
  console.log('  AVA Backend — Baseline Load Test Starting');
  console.log('='.repeat(60));
  console.log(`  Target URL : ${BASE_URL}`);
  console.log(`  VUs        : 100 virtual users`);
  console.log(`  Duration   : 60 seconds`);
  console.log(`  Thresholds : p95 < 2000ms | Error rate < 5%`);
  console.log('='.repeat(60));

  // Pre-flight check: ensure server is reachable
  const ping = http.get(`${BASE_URL}/`);
  if (ping.status !== 200) {
    console.error(`❌ Server not reachable at ${BASE_URL}. Start your server first.`);
  } else {
    console.log(`✅ Server is reachable (${ping.timings.duration.toFixed(0)}ms)`);
  }

  return { startTime: new Date().toISOString() };
}

// ─── Teardown: Runs once after load test ends ────────────────────────────────
export function teardown(data) {
  console.log('='.repeat(60));
  console.log('  AVA Backend — Load Test Completed');
  console.log(`  Started At : ${data.startTime}`);
  console.log(`  Ended At   : ${new Date().toISOString()}`);
  console.log('='.repeat(60));
  console.log('  ✅ Review the metrics summary above for:');
  console.log('     • Requests per second (RPS)');
  console.log('     • Response time (avg, min, max, p90, p95, p99)');
  console.log('     • Error rate');
  console.log('     • Threshold pass/fail status');
  console.log('='.repeat(60));
}
