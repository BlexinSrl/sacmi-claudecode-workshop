import { describe, it, expect, beforeEach } from "vitest";
import { createApp } from "../index.js";
import type { Hono } from "hono";

let app: Hono;

beforeEach(() => {
  app = createApp();
});

describe("Tasks API", () => {
  it("GET /tasks returns empty list initially", async () => {
    const res = await app.request("/tasks");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual([]);
  });

  it("POST /tasks creates task with todo status", async () => {
    const res = await app.request("/tasks", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: "Test" }),
    });
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.title).toBe("Test");
    expect(body.status).toBe("todo");
  });

  it("PUT /tasks/:id replaces existing task", async () => {
    const created = await app.request("/tasks", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: "Original" }),
    });
    const task = await created.json();

    const res = await app.request(`/tasks/${task.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: "Updated", status: "done" }),
    });
    expect(res.status).toBe(200);
    const replaced = await res.json();
    expect(replaced.title).toBe("Updated");
    expect(replaced.status).toBe("done");
  });

  it("PUT /tasks/:id returns 404 when not found", async () => {
    const res = await app.request("/tasks/999", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: "X", status: "todo" }),
    });
    expect(res.status).toBe(404);
  });

  it("DELETE /tasks/:id returns 204 when exists", async () => {
    const created = await app.request("/tasks", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: "ToDelete" }),
    });
    const task = await created.json();

    const res = await app.request(`/tasks/${task.id}`, { method: "DELETE" });
    expect(res.status).toBe(204);
  });

  it("DELETE /tasks/:id returns 404 when not found", async () => {
    const res = await app.request("/tasks/999", { method: "DELETE" });
    expect(res.status).toBe(404);
  });
});
