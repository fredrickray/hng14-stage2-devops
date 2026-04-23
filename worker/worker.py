import os
import signal
import time

import redis

_running = True


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


r = build_redis()


def _stop(*_args):
    global _running
    _running = False


signal.signal(signal.SIGTERM, _stop)
signal.signal(signal.SIGINT, _stop)


def process_job(job_id: str):
    print(f"Processing job {job_id}")
    time.sleep(2)  # simulate work
    r.hset(f"job:{job_id}", "status", "completed")
    print(f"Done: {job_id}")


def main():
    while _running:
        job = r.brpop("job", timeout=5)
        if job:
            _, job_id = job
            process_job(job_id)


if __name__ == "__main__":
    main()
