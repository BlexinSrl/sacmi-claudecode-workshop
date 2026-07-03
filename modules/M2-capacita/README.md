# Modulo M2 - Capacità · Subagents + MCP

> Obiettivo: distinguere due modi indipendenti di estendere un agente. **Subagents**: delega di task con contesto isolato. **MCP**: protocollo standard per esporre nuovi tool e risorse all'agente.

## Teoria

### Subagent

Un subagent è un agente "figlio" invocato dal main agent per gestire un task delimitato. La caratteristica chiave è il **contesto isolato**: il subagent non eredita la cronologia conversazionale del main agent - riceve solo il prompt esplicito che gli si passa.

Conseguenze:
- **Riduzione del rumore in input**: il subagent non deve discriminare tra istruzioni rilevanti per il suo task e dettagli accumulati nella conversazione precedente. La sua attenzione è concentrata sull'input ricevuto.
- **Output strutturato verso il main agent**: il main agent riceve un risultato sintetico, non l'intero ragionamento intermedio. Questo limita la crescita del contesto del main agent.
- **Parallelizzazione**: subagent indipendenti possono essere eseguiti in parallelo. Esempio: lanciare contemporaneamente tre agenti `code-reviewer` su 3 file diversi e poi fare aggregare i risultati dal main agent.

**Quando usare un subagent**: task ben definito, isolabile, con output verificabile (code review di un file, generazione di test per una funzione, ricerca focalizzata, refactor mirato).

**Quando NON usare un subagent**: conversazione iterativa, esplorazione open-ended, Q&A. In questi casi, il contesto completo è un asset, non un rumore.

#### Anatomia di un subagent

Un subagent è definito in un file `.claude/agents/<nome>.md` con frontmatter YAML:

```yaml
---
name: code-reviewer
description: Specialized subagent for code review. Invoke when you want a structured review of a file or function for correctness, security, CLAUDE.md compliance, and test coverage.
tools: Read, Grep, Glob, mcp__context7__resolve-library-id, mcp__context7__get-library-docs
model: sonnet
---
```

- `name`: identificatore invocabile (`@code-reviewer` nella chat).
- `description`: criterio di selezione del subagent da parte del main agent. L'agente principale sceglie quale subagent invocare in base alla descrizione più adatta al task da delegare, se non specificato esplicitamente.
- `tools`: **allowlist** dei tool che il subagent può usare (principio del minimo privilegio - ad esempio il code-reviewer non ha bisogno di `Edit`/`Write`).
- `model`: opzionale, per scelta di un modello specifico al subagent. `sonnet` è l'alias idiomatico di Claude Code. 

### MCP (Model Context Protocol)

MCP è uno standard che permette agli agenti AI di interagire con strumenti e sorgenti dati esterne tramite un’interfaccia comune. Un MCP server funge da ponte tra l’agente e i sistemi esterni, traducendo le richieste dell’AI nella logica specifica del tool sottostante, come API, filesystem o servizi custom.

Un MCP server è un processo, locale o remoto, che implementa questo protocollo ed espone una o più capacità utilizzabili dagli agenti. L’agente lo registra come provider di strumenti e, quando necessario, invoca i tool esposti dal server tramite MCP. Grazie a questo approccio, lo stesso MCP server può essere riutilizzato da agenti AI differenti senza dover modificare l’implementazione del server.

**Quando un MCP server fornisce valore**: quando espone capacità che **non sono già disponibili come CLI standard**. Un MCP che utilizza le API di GitHub aggiunge poco rispetto a chiedere all'agente di usare quei comandi tramite CLI.

`Context7` espone *documentazione aggiornata* delle librerie del progetto (recuperata via API). Non c'è un equivalente CLI generico.

### Combinare subagent e MCP

Le due esetensioni lavorano insieme senza sovrapporsi:
- Il **subagent** è un agente specializzato a cui deleghi un compito. Gira in un contesto separato e vede solo ciò che gli serve.
- L'**MCP** è il set di tool che quel subagent può usare mentre lavora.

In pratica: il subagent decide *cosa fare e con quali permessi*, l'MCP gli dà *gli strumenti per farlo*. Puoi assegnare MCP diversi a subagent diversi — per esempio un subagent "analisi policy" con accesso solo ai tool di lettura, e uno "deploy" con i tool che modificano risorse.

## Hands-on

### Step 1 - Attiva Context7 via MCP e usalo

Il file di configurazione MCP è già presente al root del workspace: `.mcp.json`.

```json
{
  "mcpServers": {
    "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" }
  }
}
```

Claude Code rileva automaticamente il file `.mcp.json` all'apertura del workspace e chiede l'approvazione del server `context7`. In alternativa puoi registrare un server con `claude mcp add`.

**Per gestire i server MCP** digita **`/mcp`** nel pannello Claude Code: mostra lo stato dei server registrati e permette abilitazione e autenticazione.

Ora chiedi all'agente:
> Nel progetto `@modules/M2-capacita/starters/<linguaggio>` verifica che l'handler di `POST /tasks` usi l'API attuale della libreria del mio starter (FastAPI / Hono / ASP.NET Core). Usa Context7 per recuperare le docs più recenti e dimmi se ci sono pattern più moderni per la validazione.

Osserva: l'agente invoca un tool di Context7, riceve le docs e produce un'analisi confrontando il codice attuale con l'API documentata.

### Step 2 - Crea il subagent `code-reviewer`

Crea il file `.claude/agents/code-reviewer.md` **nella root del workspace** con questo contenuto:

```markdown
---
name: code-reviewer
description: Specialized subagent for code review. Invoke when you want a structured review of a file or function for correctness, security, CLAUDE.md compliance, and test coverage.
tools: Read, Grep, Glob, mcp__context7__resolve-library-id, mcp__context7__get-library-docs
model: sonnet
---

# Code Reviewer Subagent

You are a rigorous but constructive code reviewer. Your output is a structured review.

## What you do

1. **Read CLAUDE.md** in the repo (root and the folder of the file under review) to learn the project's conventions.
2. **Read the file under review** and closely related files (tests, store, helpers).
3. **Return a structured output** in these five sections:

   ### Correctness
   Obvious bugs, unhandled edge cases, race conditions, off-by-one errors.

   ### Security
   Unvalidated input, data leaks, missing authorization, outdated dependencies.

   ### CLAUDE.md compliance
   Places where the code violates the conventions stated in CLAUDE.md (naming, error format, status codes). Cite the specific rule.

   ### Test coverage
   Cases not covered by existing tests. Suggest which tests are missing.

   ### Suggested fixes
   For each problem identified, propose a concrete fix (code snippet when applicable).

## How you operate

- Do not rewrite the code yourself. Let the main agent apply the fixes.
- Be specific: cite line and column when relevant.
- Do not invent conventions. If CLAUDE.md does not address a point, do not flag it as a violation.
- If the file is well-written, say so. Do not invent problems.
```

Nota la allowlist di tool: nessun `Edit`/`Write`, solo lettura e ricerca (`Read, Grep, Glob`). Inoltre i tool del server MCP `context7` (`mcp__context7__...`) sono inclusi, quindi il subagent può usarli per verificare le convenzioni aggiornate. Stesso principio del minimo privilegio: il subagent non modifica codice. `model: sonnet` è l'alias idiomatico di Claude Code.

Reference: `modules/M2-capacita/solution/.claude/agents/code-reviewer.md`.

### Step 3.1 - Invoca il subagent `code-reviewer`

In Claude Code invoca il subagent con **`@code-reviewer`** (digitando `@` compare il typeahead degli agenti) e chiedi:
> @code-reviewer revisiona il controller dei task (`TasksEndpoints.cs` / `routes.ts` / `main.py`) nel progetto `@modules/M2-capacita/starters/<linguaggio>` per correttezza, sicurezza e conformità ad CLAUDE.md.

Osserva:
- l'output è strutturato nei 5 blocchi definiti dal subagent (Correctness, Security, CLAUDE.md compliance, Test coverage, Suggested fixes).
- Nessuna modifica al codice è fatta dal subagent, solo suggerimenti.
- Il subagent è stato richiamato esplicitamente tramite `@code-reviewer`. In alternativa puoi descrivere il task e lasciare che sia Claude a delegare al subagent in base alla sua `description`, oppure gestire gli agenti con il comando `/agents`.

## Wrap

- **Subagent**: unità di esecuzione delegata, contesto isolato, output strutturato, eventualmente parallelizzabile.
- **MCP**: protocollo per esporre tool all'agente. Vale la pena quando il problema risolto **non è già coperto da una CLI standard**.

## Problemi?

Se ti blocchi: `solution/.claude/agents/code-reviewer.md` contiene la versione di riferimento da copiare nella root del repo.

➡️ Prossimo modulo: [`../M3-governance/README.md`](../M3-governance/README.md)