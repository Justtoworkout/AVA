// load-tests/stress-test.js
// ============================================================
// AVA Backend — Stress & Spike Test Scenarios
// Tool: k6
// ============================================================
// Three additional scenarios:
//   1. stress-test   — Ramp up to 200 VUs, find the breaking point
//   2. spike-test    — Sudden burst of 500 VUs for 10 seconds
//   3. soak-test     — 50 VUs for 10 minutes (sustained stability)
// ============================================================
//
// HOW TO RUN:
//   Stress test:  k6 run -e SCENARIO=stress load-tests/stress-test.js
//   Spike test:   k6 run -e SCENARIO=spike  load-tests/stress-test.js
//   Soak test:    k6 run -e SCENARIO=soak   load-tests/stress-test.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('error_rate');
const reqDuration = new Trend('request_duration_ms');

const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8080';
const SCENARIO = __ENV.SCENARIO || 'stress';

// ─── Scenario Configurations ──────────────────────────────────────────────────
const SCENARIOS = {
  stress: {
    executor: 'ramping-vus',
    stages: [
      { duration: '10s', target: 50  },   // Warm-up
      { duration: '20s', target: 100 },   // Normal load
      { duration: '20s', target: 150 },   // Above normal
      { duration: '20s', target: 200 },   // Stress peak
      { duration: '10s', target: 0   },   // Cool down
    ],
  },
  spike: {
    executor: 'ramping-vus',
    stages: [
      { duration: '5s',  target: 10  },   // Normal
      { duration: '5s',  target: 500 },   // Sudden spike!
      { duration: '10s', target: 500 },   // Hold spike
      { duration: '5s',  target: 10  },   // Recovery
      { duration: '5s',  target: 0   },   // Down
    ],
  },
  soak: {
    executor: 'constant-vus',
    vus: 50,
    duration: '10m',                      // 10 minutes sustained
  },
};

export const options = {
  scenarios: {
    selected: SCENARIOS[SCENARIO],
  },
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed:   ['rate<0.10'],
    error_rate:        ['rate<0.10'],
  },
};

const SAMPLE_PAYLOAD = {
  message: {
    type: 'end-of-call-report',
    call: {
      id: 'stress-test-call-001',
      startedAt: new Date(Date.now() - 60000).toISOString(),
      endedAt:   new Date().toISOString(),
      endedReason: 'customer-ended-call',
      customer: { number: '+12125551234' },
    },
    analysis: { successEvaluation: 'true' },
    transcript: 'Appointment booked for next week.',
    summary: 'Booking confirmed.',
    recordingUrl: null,
  },
};

export default function () {
  const payload = JSON.parse(JSON.stringify(SAMPLE_PAYLOAD));
  if (payload.message?.call?.id) {
    payload.message.call.id = `stress-vu${__VU}-iter${__ITER}`;
  }

  const res = http.post(`${BASE_URL}/vapiWebhook`, JSON.stringify(payload), {
    headers: { 'Content-Type': 'application/json' },
    tags:    { scenario: SCENARIO },
    timeout: '15s',
  });

  const ok = check(res, {
    '✅ Status 200':       (r) => r.status === 200,
    '✅ No server error':  (r) => r.status < 500,
    '✅ Response < 3s':    (r) => r.timings.duration < 3000,
  });

  reqDuration.add(res.timings.duration);
  errorRate.add(!ok);

  sleep(0.05);
}
