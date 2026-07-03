from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_get_tasks_returns_empty_initially():
    response = client.get("/tasks")
    assert response.status_code == 200
    assert response.json() == []


def test_post_task_creates_with_todo_status():
    response = client.post("/tasks", json={"title": "Test"})
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Test"
    assert body["status"] == "todo"
