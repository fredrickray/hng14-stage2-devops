#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${ENV_FILE:-.env}"

cleanup() {
  docker compose --env-file "$ENV_FILE" down -v --remove-orphans || true
}
trap cleanup EXIT

docker compose --env-file "$ENV_FILE" pull 2>/dev/null || true
if ! docker compose --env-file "$ENV_FILE" up -d --no-build --wait; then
  docker compose --env-file "$ENV_FILE" up -d --build --wait
fi

FE_HOST="${FRONTEND_TEST_HOST:-127.0.0.1}"
FE_PORT="${FRONTEND_PUBLISH_PORT:-3000}"

RESP="$(curl -fsS -X POST "http://${FE_HOST}:${FE_PORT}/submit")"
export RESP
JOB_ID="$(python3 -c "import json, os; print(json.loads(os.environ['RESP'])['job_id'])")"

for _ in $(seq 1 60); do
  BODY="$(curl -fsS "http://${FE_HOST}:${FE_PORT}/status/${JOB_ID}")"
  export BODY
  STATUS="$(python3 -c "import json, os; print(json.loads(os.environ['BODY']).get('status',''))")"
  if [[ "$STATUS" == "completed" ]]; then
    exit 0
  fi
  sleep 2
done

echo "Timeout waiting for job ${JOB_ID} to complete (last status: ${STATUS:-unknown})" >&2
exit 1
