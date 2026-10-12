# CLAUDE.md - Workshop Repo

## Scopo del repo

Repository del workshop "The Agent Strikes Back" su Claude Code (2026). Contiene 5 moduli hands-on con 3 starter per linguaggio (.NET 10, TypeScript, Python).

Il workshop si svolge in locale con Claude Code, a scelta tra estensione VS Code e CLI (`claude`). Il setup è nel `README.md` del root. Il workshop guida il partecipante a creare progressivamente, **a livello del root del repo** (cioè qui), le seguenti customizations Claude Code:
- `.claude/skills/endpoint-creator/SKILL.md` (creata in M1)
- `.claude/agents/code-reviewer.md` (creato in M2)
- `.claude/agents/dba.md` + hook `SubagentStart` registrato in `.claude/settings.json` + `.claude/hooks/subagent-start.{sh,ps1}` + `.claude/context/db-schema.sql` (creati in M3 - iniezione di contesto via SubagentStart)
- In M4 (Contesto & Memoria) il partecipante NON committa customizations al root del workspace: fa hands-on su **checkpoints** (feature di sessione), su un **seed di memorie di progetto** (i template di riferimento vivono in `modules/M4-contesto-memoria/solution/.claude/memory/` e vanno copiati nella cartella machine-local dell'Auto Memory), su **tokensave** (code-intelligence MCP, registrato nel setup con `tokensave install`, che scrive nel config utente `~/.claude.json` e **non** nel `.mcp.json` del repo; in M4 si indicizza con `tokensave init`, l'indice `.tokensave/` è machine-local e non committato) e sull'**episodic memory** (plugin installato nel setup che indicizza le conversazioni passate, distinto dall'Auto Memory).
- `plugins/workshop-dev-kit/` + `.claude-plugin/marketplace.json` (creati in M5 - il plugin impacchetta un sottoinsieme curato (skill `endpoint-creator` + agent `dba` + `context/db-schema.sql` + hook `SubagentStart`) e viene pubblicato in un **repo marketplace separato**, non nel workspace. I nomi plugin `claude-*` sono riservati; il matcher dell'hook nel plugin è `^workshop-dev-kit:dba$`)

## Stack per linguaggio

### .NET 10 (`modules/Mn/{starters,solution}/dotnet/`)
- ASP.NET Core 10 Minimal API
- Test: xUnit + `Microsoft.AspNetCore.Mvc.Testing`
- Struttura file:
  - `Program.cs` - bootstrap web app, chiama `MapTasks()`
  - `Tasks/TaskItem.cs` - record immutabile
  - `Tasks/TaskStore.cs` - store in-memory (singleton via DI)
  - `Tasks/TasksEndpoints.cs` - definizioni endpoint
  - `Tasks.Tests/` - test integrazione via `WebApplicationFactory<Program>`

### TypeScript / Node 20 (`modules/Mn/{starters,solution}/typescript/`)
- Hono 4 su Node 20 (ESM)
- Test: vitest
- Struttura file:
  - `src/index.ts` - `createApp()` ritorna app Hono
  - `src/tasks/store.ts` - `TaskStore` + tipi
  - `src/tasks/routes.ts` - funzione `tasksRoutes()`
  - `src/tasks/*.test.ts` - test accanto al codice
- Usa `.js` per import locali (ESM Node): `from "./tasks/routes.js"`

### Python 3.11 (`modules/Mn/{starters,solution}/python/`)
- FastAPI su Python 3.11+
- Test: pytest + `fastapi.testclient.TestClient`
- Struttura file:
  - `app/main.py` - FastAPI app + endpoint
  - `app/store.py` - `TaskStore` + dataclass `TaskItem`
  - `tests/test_tasks.py` - test integrazione

## Comandi

I comandi si eseguono **dentro la cartella `starters/` (o `solution/`) del modulo e linguaggio scelto**, es. `modules/M1-istruzioni/starters/dotnet/`. La working directory conta: gli stessi comandi lanciati dal root non trovano il progetto. Non c'è un linter/formatter configurato - `dotnet build` / `tsc` fanno da type-check.

## Convenzioni cross-linguaggio

- **Lingua**: italiano per testi rivolti ai partecipanti (README, doc, hint). Inglese per nomi file, codice, branch, commit message, skill/agent content.

## Vincoli

- NON usare un DB reale. Lo store in-memory è voluto per il workshop.
- NON aggiungere middleware (auth, logging, ecc.) negli starter.
- NON modificare i record/dataclass immutabili.
- NON modificare file in `modules/Mn/solution/` durante un modulo - sono reference per chi si blocca, da copiare al root se necessario.
- NON commitare `.env`, `audit.log`, file in `secrets/`, file `.key`/`.pem`.

## Delega ai subagent

Quando deleghi a un subagent con un file di definizione (es. `.claude/agents/code-reviewer.md`), il formato di output scritto nella definizione è il contratto. Leggi la definizione prima di scrivere il prompt.

- Il prompt di delega dice solo **cosa** fare (file target, perimetro, esclusioni specifiche del progetto). NON aggiungere né cambiare il formato di output (es. "ordina per gravità", "metti prima i finding"): sovrascrive quello prescritto dalla definizione.
- Quando il subagent risponde, riporta il report **nel formato della definizione** (stesse sezioni, stesso ordine). Puoi tradurlo, ma non riorganizzarlo in una tabella o in un riassunto tuo.
- I tuoi commenti (verifiche, avvertenze, prossimi passi) vanno dopo il report, separati.

## Dove trovare cosa

- `modules/Mn/README.md` - istruzioni del modulo n (M1, M2, M3, M4, M5).
- `modules/Mn/starters/<lang>/` - codice di partenza per il linguaggio scelto.
- `modules/Mn/solution/<lang>/` - codice allo stato finale del modulo.
- `modules/Mn/solution/.claude/` - customizations cumulative (skill, agent, hook, contesto) come reference da copiare al root del repo se ci si blocca.
- `modules/M4-contesto-memoria/` - modulo Contesto & Memoria (checkpoints, memorie, tokensave, episodic). `solution/.claude/memory/` contiene il seed di memorie di progetto (template di riferimento), `solution/<lang>/` la Task API portata avanti da M3.
- `modules/M5-distribuzione/solution/` - eccezione: è la fotografia di un **repo marketplace separato** (solo `plugins/` + `.claude-plugin/marketplace.json`), non un workspace. I sorgenti dei bundle M5 sono in `modules/M3-governance/solution/`.
