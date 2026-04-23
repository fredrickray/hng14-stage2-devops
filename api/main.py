import os
import uuid
from typing import Optional

import redis
from fastapi import FastAPI, HTTPException

app = FastAPI()

_redis_client: Optional[redis.Redis] = None


def build_redis() -> redis.Redis:
    host = os.environ["REDIS_HOST"]
    port = int(os.environ.get("REDIS_PORT", "6379"))
    password = os.environ.get("REDIS_PASSWORD") or None
    return redis.Redis(
        host=host,
        port=port,
        password=password,
        decode_responses=True,
    )


def redis_conn() -> redis.Redis:
    global _redis_client
    if _redis_client is None:
        _redis_client = build_redis()
    return _redis_client


@app.get("/health")
def health():
    redis_conn().ping()
    return {"status": "ok"}


@app.post("/jobs")
def create_job():
    job_id = str(uuid.uuid4())
    rc = redis_conn()
    rc.lpush("job", job_id)
    rc.hset(f"job:{job_id}", "status", "queued")
    return {"job_id": job_id}


@app.get("/jobs/{job_id}")
def get_job(job_id: str):
    status = redis_conn().hget(f"job:{job_id}", "status")
    if not status:
        raise HTTPException(status_code=404, detail="not found")
    return {"job_id": job_id, "status": status}
