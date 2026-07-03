import { Hono } from "hono";
import { TaskStore, type TaskStatus } from "./store.js";

export function tasksRoutes(): Hono {
  const app = new Hono();
  const store = new TaskStore();

  app.get("/tasks", (c) => c.json(store.all()));

  app.post("/tasks", async (c) => {
    const body = await c.req.json().catch(() => ({}));
    if (!body.title || typeof body.title !== "string" || !body.title.trim()) {
      return c.json({ error: "title required" }, 400);
    }
    const created = store.create(body.title);
    c.header("Location", `/tasks/${created.id}`);
    return c.json(created, 201);
  });

  app.patch("/tasks/:id", async (c) => {
    const id = Number(c.req.param("id"));
    const body = await c.req.json().catch(() => ({}));
    if (body.status !== "todo" && body.status !== "done") {
      return c.json({ error: "status must be 'todo' or 'done'" }, 400);
    }
    const updated = store.updateStatus(id, body.status as TaskStatus);
    return updated ? c.json(updated) : c.json({ error: "not found" }, 404);
  });

  return app;
}
