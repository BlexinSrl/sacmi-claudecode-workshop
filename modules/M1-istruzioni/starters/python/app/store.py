from dataclasses import dataclass, replace
from typing import Literal

Status = Literal["todo", "done"]


@dataclass(frozen=True)
class TaskItem:
    id: int
    title: str
    status: Status


class TaskStore:
    def __init__(self) -> None:
        self._tasks: list[TaskItem] = []
        self._next_id = 1

    def all(self) -> list[TaskItem]:
        return list(self._tasks)

    def create(self, title: str) -> TaskItem:
        task = TaskItem(id=self._next_id, title=title, status="todo")
        self._next_id += 1
        self._tasks.append(task)
        return task

    def update_status(self, task_id: int, status: Status) -> TaskItem | None:
        for i, t in enumerate(self._tasks):
            if t.id == task_id:
                updated = replace(t, status=status)
                self._tasks[i] = updated
                return updated
        return None
