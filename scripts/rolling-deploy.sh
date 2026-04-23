#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${1:-.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Env file not found: $ENV_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${REDIS_PASSWORD:?REDIS_PASSWORD must be set in env file}"
: "${REDIS_IMAGE:?REDIS_IMAGE must be set}"

NET_NAME="roll-$(openssl rand -hex 6)"
docker network create "$NET_NAME"

docker run -d --name redis-roll --network "$NET_NAME" \
  -e REDIS_PASSWORD="$REDIS_PASSWORD" \
  "$REDIS_IMAGE" \
  sh -c 'exec redis-server --requirepass "$REDIS_PASSWORD"'

for _ in $(seq 1 30); do
  if docker exec redis-roll redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q PONG; then
    break
  fi
  sleep 1
done

docker build -t jobstack-api:roll-old "$ROOT_DIR/api"
docker build -t jobstack-api:roll-new "$ROOT_DIR/api"

docker run -d --name api-roll-old --network "$NET_NAME" -p 18080:8000 \
  -e REDIS_HOST=redis-roll \
  -e REDIS_PORT=6379 \
  -e REDIS_PASSWORD="$REDIS_PASSWORD" \
  jobstack-api:roll-old

for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:18080/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker run -d --name api-roll-new --network "$NET_NAME" -p 18081:8000 \
  -e REDIS_HOST=redis-roll \
  -e REDIS_PORT=6379 \
  -e REDIS_PASSWORD="$REDIS_PASSWORD" \
  jobstack-api:roll-new

NEW_OK=0
for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:18081/health" >/dev/null 2>&1; then
    NEW_OK=1
    break
  fi
  sleep 1
done

if [[ "$NEW_OK" -ne 1 ]]; then
  docker rm -f api-roll-new >/dev/null 2>&1 || true
  echo "Abort: new API failed /health within 60 seconds; old API container was not stopped." >&2
  exit 1
fi

docker stop api-roll-old
docker rm api-roll-old
docker rm -f api-roll-new redis-roll >/dev/null 2>&1 || true
docker network rm "$NET_NAME" >/dev/null 2>&1 || true

echo "Rolling update completed: new API passed /health before the old API was stopped."
