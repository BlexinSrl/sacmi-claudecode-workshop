---
name: status-codes-and-responses
description: HTTP status codes per operation (GET, POST, PATCH, PUT, DELETE) and Location header on 201
metadata:
  type: project
---

## Codici di stato HTTP — Task API

| Operazione | Successo | Errore | Note |
|-----------|----------|--------|------|
| GET (lista) | **200 OK** | — | Lista vuota => `[]` con 200, non 404 |
| POST (create) | **201 Created** + header `Location: /tasks/:id` | **400 Bad Request** | Includere sempre `Location` verso la nuova risorsa |
| PATCH (update status) | **200 OK** | **404 Not Found**, **400 Bad Request** | Aggiorna solo `status`; valore non `todo`/`done` => 400 |
| PUT (replace) | **200 OK** | **404 Not Found**, **400 Bad Request** | Replace = `title` e `status` entrambi obbligatori |
| DELETE | **204 No Content** | **404 Not Found** | Nessun body in successo (204) né in 404 |

**Body di errore (4xx)**: sempre `{ "error": "<messaggio>" }` sui 400 (e sui 404 in Python via exception handler).

**Why:** allineamento con la semantica REST; i client si aspettano l'header `Location` sul 201 e il 204 senza body sul DELETE.

**How to apply:** quando aggiungi un endpoint, scegli il codice dalla tabella (200 per read/update, 201+Location per create, 204 per delete) e copri nei test sia l'happy-path sia ogni error case.

[[task-api-validation]] — correlata: formato del body d'errore 400.
