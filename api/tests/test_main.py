def test_create_job_returns_queued_job(client):
    res = client.post("/jobs")
    assert res.status_code == 200
    body = res.json()
    assert "job_id" in body
    assert len(body["job_id"]) == 36


def test_get_job_unknown_returns_404(client):
    res = client.get("/jobs/00000000-0000-0000-0000-000000000000")
    assert res.status_code == 404


def test_get_job_after_create_shows_queued_then_structure(client):
    created = client.post("/jobs").json()
    job_id = created["job_id"]
    res = client.get(f"/jobs/{job_id}")
    assert res.status_code == 200
    assert res.json() == {"job_id": job_id, "status": "queued"}
