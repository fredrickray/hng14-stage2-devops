import os

import fakeredis
import pytest

os.environ.setdefault("REDIS_HOST", "127.0.0.1")
os.environ.setdefault("REDIS_PORT", "6379")


@pytest.fixture
def client(monkeypatch):
    import main

    main._redis_client = fakeredis.FakeStrictRedis(decode_responses=True)
    from fastapi.testclient import TestClient

    with TestClient(main.app) as tc:
        yield tc
    main._redis_client = None
