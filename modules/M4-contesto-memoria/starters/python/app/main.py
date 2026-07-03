from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from app.store import TaskStore

app = FastAPI()
store = TaskStore()


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})


class CreateTaskRequest(BaseModel):
    title: str


class UpdateStatusRequest(BaseModel):
    status: str


@app.get("/tasks")
def get_tasks() -> list[dict]:
    return [t.__dict__ for t in store.all()]


@app.post("/tasks", status_code=201)
def create_task(req: CreateTaskRequest, response: Response) -> dict:
    if not req.title.strip():
        raise HTTPException(status_code=400, detail="title required")
    item = store.create(req.title)
    response.headers["Location"] = f"/tasks/{item.id}"
    return item.__dict__


@app.patch("/tasks/{task_id}")
def update_status(task_id: int, req: UpdateStatusRequest) -> dict:
    if req.status not in ("todo", "done"):
        raise HTTPException(status_code=400, detail="status must be 'todo' or 'done'")
    updated = store.update_status(task_id, req.status)
    if updated is None:
        raise HTTPException(status_code=404, detail="not found")
    return updated.__dict__


class ReplaceTaskRequest(BaseModel):
    title: str
    status: str


@app.put("/tasks/{task_id}")
def replace_task(task_id: int, req: ReplaceTaskRequest) -> dict:
    if not req.title.strip():
        raise HTTPException(status_code=400, detail="title required")
    if req.status not in ("todo", "done"):
        raise HTTPException(status_code=400, detail="status must be 'todo' or 'done'")
    replaced = store.replace(task_id, req.title, req.status)
    if replaced is None:
        raise HTTPException(status_code=404, detail="not found")
    return replaced.__dict__


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: int) -> None:
    if not store.delete(task_id):
        raise HTTPException(status_code=404, detail="not found")
