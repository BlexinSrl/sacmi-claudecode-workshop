export type TaskStatus = "todo" | "done";

export interface TaskItem {
  id: number;
  title: string;
  status: TaskStatus;
}

export class TaskStore {
  private tasks: TaskItem[] = [];
  private nextId = 1;

  all(): TaskItem[] {
    return [...this.tasks];
  }

  create(title: string): TaskItem {
    const task: TaskItem = { id: this.nextId++, title, status: "todo" };
    this.tasks.push(task);
    return task;
  }

  updateStatus(id: number, status: TaskStatus): TaskItem | null {
    const idx = this.tasks.findIndex((t) => t.id === id);
    if (idx < 0) return null;
    this.tasks[idx] = { ...this.tasks[idx], status };
    return this.tasks[idx];
  }
}
