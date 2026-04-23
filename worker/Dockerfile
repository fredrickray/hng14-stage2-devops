# syntax=docker/dockerfile:1
FROM python:3.12-slim AS builder
WORKDIR /build
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir "pip==24.3.1" \
    && pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
RUN groupadd --system --gid 10001 worker \
    && useradd --system --uid 10001 --gid worker --no-create-home --home-dir /app worker
WORKDIR /app
COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH" PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY worker.py .
USER worker
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os,redis; r=redis.Redis(host=os.environ['REDIS_HOST'],port=int(os.environ.get('REDIS_PORT','6379')),password=os.environ.get('REDIS_PASSWORD') or None,decode_responses=True,socket_connect_timeout=3); r.ping()"
CMD ["python", "worker.py"]
