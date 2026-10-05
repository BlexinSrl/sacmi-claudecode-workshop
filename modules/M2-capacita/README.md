# Modulo M2 - Capacità · Subagents + MCP

> Obiettivo: distinguere due modi indipendenti di estendere un agente. **MCP**: protocollo standard per dare all'agente nuovi tool. **Subagents**: delega di un task a un agente specializzato con contesto isolato.

## Teoria

### MCP (Model Context Protocol)

MCP è uno standard che permette agli agenti AI di usare strumenti e sorgenti dati esterne tramite un'interfaccia comune. Un **MCP server** è un processo, locale o remoto, che implementa il protocollo ed espone uno o più tool. L'agente lo registra e, quando serve, invoca i suoi tool. Lo stesso server può essere riusato da agenti diversi senza modifiche.

**Quando un MCP server porta valore**: quando espone capacità che **non sono già disponibili come CLI standard**. Un MCP che chiama le API di GitHub aggiunge poco rispetto a chiedere all'agente di usare la CLI `gh`.

**Context7** espone *documentazione aggiornata* delle librerie (recuperata via API) tramite due tool: `resolve-library-id` (trova la libreria) e `query-docs` (interroga la sua documentazione). Non esiste un equivalente CLI generico.

In Claude Code i tool di un server MCP hanno un nome nella forma `mcp__<server>__<tool>`, ad esempio `mcp__context7__query-docs`.

### Subagent

Un subagent è un agente "figlio" invocato dall'agente principale per gestire un task delimitato. La caratteristica chiave è il **contesto isolato**: il subagent non eredita la cronologia della conversazione, riceve solo il prompt che gli viene passato.

Conseguenze:
- **Meno rumore in input**: il subagent non deve distinguere tra istruzioni rilevanti e dettagli accumulati nella conversazione. La sua attenzione è sul task.
- **Output sintetico verso l'agente principale**: l'agente principale riceve il risultato, non tutto il ragionamento intermedio. Il suo contesto cresce meno.
- **Parallelizzazione**: subagent indipendenti possono girare in parallelo (es. tre `code-reviewer` su tre file diversi, poi l'agente principale aggrega i risultati).

**Quando usare un subagent**: task ben definito, isolabile, con output verificabile (code review di un file, generazione di test per una funzione, ricerca mirata).

**Quando NON usarlo**: conversazione iterativa, esplorazione aperta, domande e risposte. In questi casi il contesto completo è un vantaggio, non rumore.

#### Anatomia di un subagent

Un subagent di progetto è un file `.claude/agents/<nome>.md` con frontmatter YAML:

```yaml
---
name: code-reviewer
description: Specialized subagent for code review. Invoke when you want a structured review of a file or function for correctness, security, CLAUDE.md compliance, and test coverage.
tools: Read, Grep, Glob, mcp__context7__resolve-library-id, mcp__context7__query-docs
model: sonnet
---
```

- `name`: identificatore del subagent. In chat lo richiami con `@agent-<name>` (es. `@agent-code-reviewer`).
- `description`: criterio con cui l'agente principale decide a quale subagent delegare, se non lo indichi tu esplicitamente.
- `tools`: **allowlist** dei tool che il subagent può usare (principio del minimo privilegio: un reviewer non ha bisogno di `Edit`/`Write`). Se ometti il campo, il subagent eredita tutti i tool.
- `model`: opzionale, il modello da usare per il subagent (`sonnet`, `opus`, `haiku` o `inherit`).

### Combinare subagent e MCP

Le due estensioni lavorano insieme senza sovrapporsi:
- il **subagent** decide *cosa fare e con quali permessi*: gira in un contesto separato e vede solo ciò che gli serve;
- l'**MCP** gli dà *gli strumenti per farlo*.

Puoi assegnare tool MCP diversi a subagent diversi: ad esempio un subagent di analisi con i soli tool di lettura e uno di deploy con i tool che modificano risorse.

## Hands-on

**Prima di iniziare**: prepara lo starter di questo modulo (`modules/M2-capacita/starters/<linguaggio>/`) come descritto nello [Step 3 del Setup](../../README.md#step-3---prepara-lo-starter-del-tuo-linguaggio). I test devono passare (6 test). Questo starter contiene già `PUT` e `DELETE` dal modulo M1.

### Step 1 - Usa Context7 via MCP

Il server è già configurato nel file `.mcp.json` al root del repo:

```json
{
  "mcpServers": {
    "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" }
  }
}
```

`.mcp.json` è la configurazione MCP **di progetto**: è committata nel repo, quindi chiunque apra il workspace ottiene gli stessi server (dopo averli approvati). In alternativa un server si può registrare da terminale con `claude mcp add`.

**Checkpoint**: digita `/mcp` in Claude Code. `context7` deve risultare connesso. Se non lo è, abilitalo da quel menu (vedi [Setup, Step 4](../../README.md#step-4---approva-il-server-mcp-context7)).

In una nuova conversazione chiedi:

> Nel progetto `@modules/M2-capacita/starters/<linguaggio>` verifica che l'handler di `POST /tasks` usi l'API attuale della libreria del mio starter (FastAPI / Hono / ASP.NET Core). Usa Context7 per recuperare la documentazione più recente e dimmi se ci sono pattern più moderni per la validazione.

**Risultato atteso**: nel flusso della risposta compaiono le chiamate ai tool `resolve-library-id` e `query-docs` di Context7 (approva quando Claude chiede il permesso). La risposta confronta il codice dello starter con la documentazione recuperata. Non serve applicare i suggerimenti.

### Step 2 - Crea il subagent `code-reviewer`

Crea il file `.claude/agents/code-reviewer.md` **al root del repository** con questo contenuto:

```markdown
---
name: code-reviewer
description: Specialized subagent for code review. Invoke when you want a structured review of a file or function for correctness, security, CLAUDE.md compliance, and test coverage.
tools: Read, Grep, Glob, mcp__context7__resolve-library-id, mcp__context7__query-docs
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

Nota l'allowlist dei tool: nessun `Edit`/`Write`, solo lettura e ricerca (`Read, Grep, Glob`) più i due tool di Context7, che il subagent può usare per verificare le API aggiornate delle librerie. Il subagent non può modificare il codice: può solo suggerire.

**Checkpoint**: apri una **nuova conversazione** e digita `/agents`, oppure digita `@` nel prompt: `code-reviewer` deve comparire tra gli agenti disponibili.

### Step 3 - Invoca il subagent `code-reviewer`

Nel prompt digita `@`, scegli `code-reviewer` dal menu (viene inserito come `@agent-code-reviewer`) e completa la richiesta indicando il file del tuo linguaggio (`Tasks/TasksEndpoints.cs`, `src/tasks/routes.ts` o `app/main.py`):

> @agent-code-reviewer revisiona il file degli endpoint dei task nel progetto `@modules/M2-capacita/starters/<linguaggio>` per correttezza, sicurezza e conformità a CLAUDE.md.

**Risultato atteso**:
- nella chat compare l'esecuzione del subagent `code-reviewer`, separata dalla conversazione principale;
- l'output è strutturato nelle 5 sezioni definite nel file (Correctness, Security, CLAUDE.md compliance, Test coverage, Suggested fixes);
- **nessun file viene modificato**: il subagent non ha i tool per farlo.

In alternativa puoi descrivere il task senza `@agent-...` (es. *"fai una code review di ..."*) e lasciare che sia Claude a delegare al subagent in base alla sua `description`.

### Step 4 (opzionale) - Applica i suggerimenti

Chiedi all'agente principale di applicare i fix proposti, ad esempio:

> Aggiungi i test mancanti suggeriti dal code-reviewer e verifica che passino.

**Risultato atteso**: è l'agente principale (non il subagent) a modificare i file. Nella solution di riferimento questo passo porta i test da 6 a 10.

## Wrap

- **MCP**: protocollo per dare tool nuovi all'agente. Vale la pena quando il problema **non è già coperto da una CLI standard**.
- **Subagent**: unità di esecuzione delegata, contesto isolato, output strutturato, tool limitati da un'allowlist, eventualmente parallelizzabile.

## Problemi?

- **`context7` non connesso**: digita `/mcp`, abilita il server e riprova in una nuova conversazione. L'endpoint è pubblico, ma richiede connessione a internet.
- **`code-reviewer` non compare con `@`**: verifica che il file sia in `.claude/agents/` al root del repo (non nello starter) e apri una nuova conversazione.
- Subagent di riferimento: `modules/M2-capacita/solution/.claude/agents/code-reviewer.md`, da copiare in `.claude/agents/` al root del repo.

➡️ Prossimo modulo: [`../M3-governance/README.md`](../M3-governance/README.md)
