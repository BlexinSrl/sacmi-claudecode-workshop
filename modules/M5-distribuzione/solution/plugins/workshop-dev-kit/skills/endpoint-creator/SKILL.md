---
name: endpoint-creator
description: Use when creating a new REST endpoint in this repo. Covers validation, code location, status codes, test structure, and naming.
---

# How to create a REST endpoint in this repo

## 1. Code location
- .NET: `Tasks/TasksEndpoints.cs` (inside `MapTasks`)
- TypeScript: `src/tasks/routes.ts` (inside `tasksRoutes()`)
- Python: `app/main.py` (function decorated with `@app.<verb>`)

## 2. Input validation
- Invalid input => 400 with body `{ "error": "<short message>" }`
- Python: pydantic.BaseModel; TS: type-narrowing; .NET: record + manual checks

## 3. Status codes
- 200 GET · 201 POST + Location header · 200 PUT (replace) · 200 PATCH · 204 No Content (DELETE) · 404 not found · 400 validation

## 4. Tests
Every endpoint ships with one happy path test and one error case test.

## 5. Naming
Kebab-case paths (e.g. `/tasks/by-status`). Typed path params (`{id:int}` in .NET).
