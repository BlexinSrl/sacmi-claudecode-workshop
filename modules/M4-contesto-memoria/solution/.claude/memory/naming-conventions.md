---
name: naming-conventions
description: Kebab-case endpoint paths, in-memory store, immutable Task record/dataclass
metadata:
  type: project
---

## Convenzioni di naming e struttura — Task API

### Path degli endpoint
- **Formato**: kebab-case nei path (es. `/tasks`, `/tasks/stats`), mai camelCase (`/taskStats`).

### Strutture dati immutabili
- Il modello `TaskItem` è **immutabile** in tutti e tre i linguaggi e NON va modificato:
  - .NET: `record TaskItem` in `Tasks/TaskItem.cs`.
  - TypeScript: tipo `TaskItem` in `src/tasks/store.ts` (campi `readonly`).
  - Python: `@dataclass(frozen=True)` `TaskItem` in `app/store.py`.
- Per "aggiornare" un task si crea una nuova istanza e si rimpiazza quella nello store (vedi `update_status`/`replace`), non si muta l'oggetto esistente.

### Store
- Lo store è **in-memory** e voluto così per il workshop: `TaskStore` come singleton (DI in .NET, istanza condivisa in TS/Python). **Niente DB reale.**

**Why:** l'immutabilità evita mutazioni accidentali nello store condiviso; lo store in-memory tiene gli starter minimali e focalizzati sul tema del modulo.

**How to apply:** nuovi endpoint mantengono `TaskItem` immutabile e usano i metodi dello store per creare/rimpiazzare; non introdurre un DB né middleware (auth, logging, ecc.).

[[task-api-validation]] — correlata: la validazione è parte del contratto d'input.
