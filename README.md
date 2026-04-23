# HNG14 Stage 2 — Containerized job stack

Three services (frontend, API, worker) plus Redis process background jobs. This fork adds production-oriented Docker images, Compose wiring, CI/CD, and documents every application defect in `FIXES.md`.

## Prerequisites

- Docker Engine **24+** and Docker Compose **v2** (`docker compose version`)
- (Optional, for local dev without Docker) Node.js **20+**, Python **3.12+**, and a reachable Redis instance

## Quick start (Docker)

1. **Fork / clone** this public repository (do not open a PR to the upstream starter).

2. **Create your local env file** (never commit it):

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and replace `__SET_A_STRONG_REDIS_PASSWORD__` with a long random value. Adjust CPU/memory limits or image tags if your machine is constrained.

3. **Build, start, and wait for health checks:**

   ```bash
   docker compose --env-file .env up -d --build --wait
   ```

4. **Open the UI** at `http://127.0.0.1:${FRONTEND_PUBLISH_PORT}` (default port **3000** from `.env.example`).

5. **Sanity check**

   - Click **Submit New Job**; you should see a UUID echoed under the button.
   - Within a few seconds the row should move from `queued` to `completed` (the worker sleeps ~2 seconds per job).
   - Redis is **not** published on the host; only the frontend port mapping is exposed by default.

6. **Logs (optional):**

   ```bash
   docker compose --env-file .env logs -f api worker frontend
   ```

7. **Shut down and remove volumes:**

   ```bash
   docker compose --env-file .env down -v
   ```

## Scripts

- `scripts/integration-test.sh` — brings the stack up (pull/build as needed), posts a job through the frontend, polls until `completed`, then tears the stack down. Uses `ENV_FILE` (default `.env`).
- `scripts/rolling-deploy.sh` — demonstrates a health-gated API swap (see script header comments in the file). Pass the path to an env file (same shape as `.env.example`).

## CI/CD

GitHub Actions workflow `.github/workflows/ci.yml` runs, in order:

`lint` → `test` → `build` (includes image push to an ephemeral registry, Trivy SARIF upload + CRITICAL gate, integration test) → `deploy` (rolling API demo on pushes to `main` only).

## Related docs

- `FIXES.md` — every bug fixed from the starter, with file and line references.
- `.env.example` — required environment variables for Compose and local tooling.
