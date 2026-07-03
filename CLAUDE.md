# CLAUDE.md - Workshop Repo

## Scopo del repo

Repository del workshop "The Agent Strikes Back" su Claude Code (2026). Contiene 5 moduli hands-on con 3 starter per linguaggio (.NET 10, TypeScript, Python).

Il workshop guida il partecipante a creare progressivamente, **a livello del root del repo** (cioè qui), le seguenti customizations Claude Code:
- `.claude/skills/endpoint-creator/SKILL.md` (creata in M1)
- `.claude/agents/code-reviewer.md` (creato in M2)
- `.claude/agents/dba.md` + hook `SubagentStart` e `PreToolUse` registrati in `.claude/settings.json` + `.claude/hooks/*.{sh,ps1}` + `.claude/context/db-schema.sql` + `.claude/policy.yml` (creati in M3 - iniezione di contesto via SubagentStart e policy enforcement via PreToolUse)
- In M4 (Contesto & Memoria) il partecipante NON committa customizations al root del workspace: fa hands-on su **checkpoints** (feature di sessione), su un **seed di memorie di progetto** (di cui i template di riferimento vivono in `modules/M4-contesto-memoria/solution/.claude/memory/`), registra **tokensave** (code-intelligence MCP) in `.mcp.json` con `tokensave init` (l'indice `.tokensave/` è machine-local, non committato) e usa l'**episodic memory** (Auto Memory machine-local) per recuperare decisioni da conversazioni passate.
- `plugins/claude-safety-guard/` + `.claude-plugin/marketplace.json` (creati in M5 - il plugin impacchetta un sottoinsieme curato (skill + code-reviewer + safety hook) e viene pubblicato in un **repo marketplace separato**, non nel workspace)

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

I comandi si eseguono **dentro la cartella `starters/` (o `solution/`) del modulo e linguaggio scelto**, es. `modules/M1-istruzioni/starters/dotnet/`. La working directory conta: gli stessi comandi lanciati dal root non trovano il progetto. Non c'è un linter/formatter configurato — `dotnet build` / `tsc` fanno da type-check.

### .NET 10
```bash
dotnet restore
dotnet build                                                     # compile / type-check
dotnet test Tasks.Tests                                          # ⚠️ indica SEMPRE il progetto di test
dotnet test Tasks.Tests --filter "FullyQualifiedName~GetTasks"   # singolo test (match sul nome)
dotnet run                                                       # server su http://localhost:5000
```
> ⚠️ `dotnet test` "nudo" da questa cartella prende `TaskApi.csproj` (la web app, senza test) ed esce **0 senza eseguire nulla** → falso verde. Passa sempre `Tasks.Tests`.

### TypeScript (Node 20)
```bash
npm install
npm run build                                # tsc (type-check)
npm test                                     # vitest run — tutti i test
npx vitest run src/tasks/routes.test.ts      # singolo file
npx vitest run -t "creates"                  # singolo test per nome
npm run dev                                  # server su http://localhost:3000 (tsx watch)
```

### Python 3.11
```bash
python3 -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest                                               # tutti i test
pytest tests/test_tasks.py::test_get_tasks_returns_empty_initially   # singolo test
uvicorn app.main:app                                 # server su http://localhost:8000
```

## Convenzioni cross-linguaggio

- **Lingua**: italiano per testi rivolti ai partecipanti (README, doc, hint). Inglese per nomi file, codice, branch, commit message, skill/agent content.
- **Naming endpoint**: kebab-case nei path (`/tasks/stats`, non `/taskStats`).
- **Validazione input**: invalido => 400 con body `{ "error": "<messaggio>" }`.
- **Status code**: 200 GET, 201 POST con Location header, 200 PATCH, 204 No Content (DELETE), 404 not found, 400 validation error.
- **Test obbligatorio**: ogni endpoint ha 1 happy-path + 1 error case.

## Vincoli

- NON usare un DB reale. Lo store in-memory è voluto per il workshop.
- NON aggiungere middleware (auth, logging, ecc.) negli starter.
- NON modificare i record/dataclass immutabili.
- NON modificare file in `modules/Mn/solution/` durante un modulo - sono reference per chi si blocca, da copiare al root se necessario.
- NON commitare `.env`, `audit.log`, file in `secrets/`, file `.key`/`.pem`.

## Dove trovare cosa

- `modules/Mn/README.md` - istruzioni del modulo n (M1, M2, M3, M4, M5).
- `modules/Mn/starters/<lang>/` - codice di partenza per il linguaggio scelto.
- `modules/Mn/solution/<lang>/` - codice allo stato finale del modulo.
- `modules/Mn/solution/.claude/` - customizations cumulative (skill, agent, hook, policy) come reference da copiare al root del repo se ci si blocca.
- `modules/M4-contesto-memoria/` - modulo Contesto & Memoria (checkpoints, memorie, tokensave, episodic). `solution/.claude/memory/` contiene il seed di memorie di progetto (template di riferimento), `solution/<lang>/` la Task API portata avanti da M3.
- `modules/M5-distribuzione/solution/` - eccezione: è la fotografia di un **repo marketplace separato** (solo `plugins/` + `.claude-plugin/marketplace.json`), non un workspace. I sorgenti dei bundle M5 sono in `modules/M3-governance/solution/`.
