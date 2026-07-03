---
name: task-api-validation
description: 400 error format and validation rules for Task API endpoints
metadata:
  type: project
---

## Regole di validazione — Task API

Input invalido restituisce **sempre HTTP 400** con body:

```json
{ "error": "<messaggio descrittivo>" }
```

### Validazione per endpoint

- **POST /tasks**: richiede `title` (stringa non vuota). Vuoto/whitespace => 400 `title required`.
- **PATCH /tasks/:id**: richiede `status`, accetta solo `"todo"` o `"done"`. Valore diverso => 400 `status must be 'todo' or 'done'`.
- **PUT /tasks/:id**: semantica di replace, richiede SIA `title` non vuoto SIA `status` valido (`todo`/`done`). Manca/invalido uno dei due => 400.

### Implementazione per linguaggio

- .NET: `Tasks/TasksEndpoints.cs` — validazione manuale (`IsNullOrWhiteSpace`, confronto `status`) prima della logica, ritorna `Results.BadRequest(new { error = ... })`.
- TypeScript: validazione nelle route in `src/tasks/routes.ts`, ritorna `c.json({ error: ... }, 400)`.
- Python: `pydantic.BaseModel` per la forma + check espliciti; un `exception_handler(HTTPException)` in `app/main.py` mappa ogni errore a `{"error": exc.detail}`.

**Why:** il client deve poter contare su uno schema d'errore identico cross-linguaggio; la validazione precede sempre la logica di business.

**How to apply:** ogni nuovo endpoint valida l'input prima di toccare lo store; aggiungi sempre un test sull'error case che asserisce `{ "error": ... }` e lo status 400.

[[status-codes-and-responses]] — il 400 fa parte della tabella dei codici di stato.
