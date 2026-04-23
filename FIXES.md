# Bug fixes and hardening

Each entry references the **starter** file and line numbers **before** this fork’s changes, then describes the defect and the fix.

---

## `api/.env` (entire file, lines 1–2)

**Problem:** A real `.env` file was committed containing `REDIS_PASSWORD` and `APP_ENV`. Assignment rules forbid committing `.env` or credentials, and Docker must not bake secrets into images.

**Change:** Removed `api/.env` from the tree. Added root `.gitignore` rules for `.env` and documented required variables in `.env.example`. If this file ever existed on `main` in your fork’s history, rewrite history before submission (e.g. `git filter-repo`) so secrets are not recoverable.

---

## `api/main.py` line 8

**Problem:** `redis.Redis(host="localhost", port=6379)` hardcodes the broker address. Inside Docker the API must reach the `redis` service by DNS name, not `localhost`.

**Change:** Build the client from `REDIS_HOST`, `REDIS_PORT`, and optional `REDIS_PASSWORD`, with `decode_responses=True`.

---

## `api/main.py` lines 17–22

**Problem:** Unknown jobs returned HTTP 200 with `{"error": "not found"}` while the frontend and tests expect a stable `status` field or a real HTTP error. `status.decode()` was also brittle once `decode_responses` is enabled (returns `str`).

**Change:** Return `404` with `HTTPException` for missing jobs. Return `status` as a string consistently.

---

## `api/main.py` (missing endpoint after line 8 in starter)

**Problem:** No readiness probe existed for orchestrators or `HEALTHCHECK`. Redis outages could not be detected until traffic failed.

**Change:** Added `GET /health` that runs `PING` against Redis.

---

## `api/main.py` (module-level Redis client and testability)

**Problem:** A single module-level `r` made unit tests depend on a live Redis instance.

**Change:** Introduced `_redis_client` and `redis_conn()` so tests can inject `fakeredis` via `monkeypatch` / fixture without starting Redis.

---

## `api/requirements.txt` lines 1–3

**Problem:** Unpinned dependencies make builds non-reproducible and break CI caching.

**Change:** Pinned `fastapi`, `uvicorn[standard]`, and `redis` to specific versions.

---

## `worker/worker.py` line 6

**Problem:** Same hardcoded `localhost` Redis host as the API, so the worker fails in Compose.

**Change:** Same environment-driven Redis client as the API, with `decode_responses=True`.

---

## `worker/worker.py` lines 14–18 (control flow)

**Problem:** Infinite `while True` at import time with no cooperative shutdown: `SIGTERM` from Docker could not stop the worker cleanly, and `signal` was imported but unused.

**Change:** Wrapped the loop in `main()`, added `_running` guarded by `SIGTERM`/`SIGINT`, and call `main()` only under `if __name__ == "__main__":` so imports do not start the loop.

---

## `worker/worker.py` line 18 (with `decode_responses=False` in starter)

**Problem:** With `decode_responses=True`, `job_id` from `BRPOP` is already a `str`; calling `.decode()` would raise `AttributeError`.

**Change:** Pass `job_id` directly to `process_job` as a string.

---

## `worker/requirements.txt` line 1

**Problem:** Unpinned `redis`.

**Change:** Pinned `redis` to match the API stack.

---

## `frontend/app.js` line 6

**Problem:** `API_URL` was hardcoded to `http://localhost:8000`, so the frontend container called its own loopback instead of the `api` service.

**Change:** Read `process.env.API_URL` with a localhost default for bare-metal dev.

---

## `frontend/app.js` lines 29–31 (listen binding)

**Problem:** `app.listen(3000, () => …)` binds to the default host (often IPv6-only or loopback nuances). In containers the process must listen on `0.0.0.0`.

**Change:** Use `HOST` and `PORT` from the environment with safe defaults (`0.0.0.0`, `3000`).

---

## `frontend/app.js` lines 20–26 (error handling for `/status`)

**Problem:** Axios errors on 404 were mapped to HTTP 500 and lost the upstream status, confusing clients.

**Change:** Forward `err.response?.status` when present so 404 from the API surfaces correctly.

---

## `frontend/views/index.html` lines 23–37 (starter)

**Problem:** Submit and poll paths assumed success JSON only. Missing `job_id` or `error` keys led to `undefined` UI text and infinite polling on errors.

**Change:** Check `res.ok`, handle `data.error`, and stop polling when the status cannot be read.

---

## `frontend/package.json` (scripts / dev tooling)

**Problem:** No lint script for CI `eslint` stage.

**Change:** Added `lint` script and `eslint` + `globals` devDependencies; added `eslint.config.js`.

---

## `README.md` line 1

**Problem:** The repository did not explain how to run or grade the stack.

**Change:** Replaced with full operator documentation (see current `README.md`).
