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


def test_put_task_replaces_existing():
    created = client.post("/tasks", json={"title": "Original"})
    task = created.json()

    response = client.put(f"/tasks/{task['id']}", json={"title": "Updated", "status": "done"})
    assert response.status_code == 200
    replaced = response.json()
    assert replaced["title"] == "Updated"
    assert replaced["status"] == "done"


def test_put_task_returns_404_when_not_found():
    response = client.put("/tasks/999", json={"title": "X", "status": "todo"})
    assert response.status_code == 404


def test_delete_task_returns_204_when_exists():
    created = client.post("/tasks", json={"title": "ToDelete"})
    task = created.json()

    response = client.delete(f"/tasks/{task['id']}")
    assert response.status_code == 204


def test_delete_task_returns_404_when_not_found():
    response = client.delete("/tasks/999")
    assert response.status_code == 404
