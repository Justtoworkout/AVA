# AVA Backend — Load Testing Guide

## Overview

This directory contains k6-based load test scripts for the AVA webhook backend.

| File | Purpose |
|------|---------|
| `baseline-load-test.js` | **100 VUs × 60 seconds** — standard baseline test |
| `stress-test.js` | Ramp-up stress / sudden spike / 10-min soak test |
| `generate-report.js` | Generates Excel report from k6 JSON output |

---

## 1. Install k6

**Windows (Chocolatey):**
```bash
choco install k6
```
**Windows (winget):**
```bash
winget install k6
```
**Mac:**
```bash
brew install k6
```

---

## 2. Start Your Backend

```bash
cd backend
node server.js
# Server running on http://localhost:8080
```

---

## 3. Run Baseline Test (100 VUs, 1 minute)

```bash
k6 run load-tests/baseline-load-test.js
```

**Against a remote server:**
```bash
k6 run -e TARGET_URL=https://your-server.onrender.com load-tests/baseline-load-test.js
```

---

## 4. What You Will See

```
          /\      |‾‾| /‾‾/   /‾‾/   
     /\  /  \     |  |/  /   /  /    
    /  \/    \    |     (   /   ‾‾\  
   /          \   |  |\  \ |  (‾)  | 
  / __________ \  |__| \__\ \_____/ .io

  execution: local
     script: load-tests/baseline-load-test.js
     output: -

  scenarios: (100.00%) 1 scenario, 100 max VUs, 1m30s max duration
           * baseline_load: 100 looping VUs for 1m0s (gracefulStop: 30s)

  ✓ ✅ Webhook returns 200
  ✓ ✅ Webhook not 5xx error
  ✓ ✅ Webhook response time < 2000ms
  ✓ ✅ Response is JSON

  checks.........................: 99.80%  ✓ 4990    ✗ 10
  data_received..................: 2.1 MB  35 kB/s
  data_sent......................: 3.4 MB  57 kB/s
  error_rate.....................: 0.20%  ✓ 0       ✗ 0
  http_req_blocked...............: avg=1.2ms  min=1µs   med=3µs   max=58ms
  http_req_duration..............: avg=248ms  min=42ms  med=210ms max=1.54s
    { type:health }...............: avg=38ms   min=21ms  med=35ms  max=120ms
    { type:webhook }.............: avg=258ms  min=42ms  med=220ms max=1.54s
  ✓ { p(99)<5000 }
  http_req_failed................: 0.00%  ✓ 0      ✗ 5024
  http_reqs......................: 5024   83.73/s          ← REQUESTS PER SECOND
  iteration_duration.............: avg=304ms
  iterations.....................: 5024   83.73/s
  vus............................: 100    min=100 max=100
  vus_max........................: 100    min=100 max=100

  ✓ http_req_duration............: p(95)=812ms < 2000ms  ✅ PASS
  ✓ http_req_failed..............: 0.00%   < 5.00%       ✅ PASS
```

### Key Metrics Explained

| Metric | Example Value | What It Means |
|--------|--------------|---------------|
| **http_reqs/s** | 83.73/s | Your API handled ~84 requests every second |
| **avg duration** | 248ms | Average time to complete a request |
| **min duration** | 42ms | Fastest request served |
| **max duration** | 1.54s | Slowest request (under load) |
| **p95** | 812ms | 95% of requests completed within 812ms |
| **error rate** | 0.00% | Zero errors during the test |

---

## 5. Generate Excel Report

After running the test with JSON output:

```bash
# Step 1: Run with JSON output
k6 run --out json=load-tests/results/baseline-results.json load-tests/baseline-load-test.js

# Step 2: Install dependencies
cd load-tests && npm install

# Step 3: Generate Excel report
node load-tests/generate-report.js
# Output: load-tests/results/load-test-report.xlsx
```

---

## 6. Other Test Scenarios

```bash
# Stress Test (ramp to 200 VUs — find breaking point)
k6 run -e SCENARIO=stress load-tests/stress-test.js

# Spike Test (sudden burst of 500 VUs for 10 seconds)
k6 run -e SCENARIO=spike load-tests/stress-test.js

# Soak Test (50 VUs for 10 minutes — sustained stability)
k6 run -e SCENARIO=soak load-tests/stress-test.js
```

---

## 7. Performance Baselines (Expected for AVA)

| Scenario | Expected RPS | Expected Avg | Expected p95 |
|----------|-------------|-------------|-------------|
| Baseline (100 VUs) | 80–120 req/s | 180–300ms | < 1000ms |
| Stress (200 VUs) | 150–200 req/s | 300–600ms | < 2000ms |
| Spike (500 VUs) | 200–350 req/s | 800–1500ms | < 4000ms |
| Soak (50 VUs, 10m) | 40–80 req/s | 200–350ms | < 1200ms |
