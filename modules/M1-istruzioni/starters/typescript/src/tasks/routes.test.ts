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
});
