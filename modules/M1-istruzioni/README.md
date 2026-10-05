# Modulo M1 - Istruzioni · CLAUDE.md + Skills

> Obiettivo: capire come si descrive un repo in un file `CLAUDE.md` e come si crea una Skill. Vedere in pratica la differenza tra "regole sempre attive" e "know-how caricato quando serve".

## Teoria

### CLAUDE.md

`CLAUDE.md` è il file con cui descrivi il *contratto* del repository a Claude Code. È un file Markdown che Claude Code carica automaticamente all'avvio di ogni conversazione e tiene nel contesto per tutta la sessione.

**Cosa includere**:
- **Regole architetturali**: stack tecnologico, layering, decisioni di design che non si vogliono violare.
- **Convenzioni di codice**: naming, validazione, gestione errori, struttura dei test.
- **Vincoli non negoziabili**: cose che l'agente non deve mai fare ("non modificare X", "esegui sempre Y prima di un commit").
- **Comandi e punti di ingresso**: come si compila e si testa, dove cercare cosa nel repository.

**Cosa NON includere**:
- Documentazione esaustiva del progetto.
- Esempi lunghi di codice (vanno in una skill o nei commenti del codice).
- Storia delle decisioni o changelog (lo dice `git log`).
- Informazioni che cambiano spesso: se il file non viene aggiornato, l'agente lavora con istruzioni obsolete.

**Lunghezza**: punta a meno di 200 righe. Oltre, il costo in token di ogni sessione cresce e l'aderenza alle regole cala: è il segnale che alcune istruzioni vanno spostate in una Skill.

### Skill

Una skill è una cartella con istruzioni e risorse che danno all'agente know-how procedurale su *come* fare qualcosa di specifico. L'agente la carica solo quando serve, in base alla sua `description`: il prompt resta leggero e il costo in token si paga solo quando quel know-how è davvero necessario.

La struttura è la seguente:

```
.claude/skills/<nome-skill>/
├── SKILL.md          <= frontmatter YAML + corpo istruzioni
├── scripts/          <= (opzionale) script eseguibili
└── resources/        <= (opzionale) template, esempi, schema
```

Il file `SKILL.md` inizia con un frontmatter YAML con due campi principali:

```yaml
---
name: endpoint-creator
description: Use when creating a new REST endpoint in this repo. Covers validation, code location, status codes, test structure, and naming.
---
```

- `name`: identificatore tecnico in kebab-case. Diventa anche lo slash command (`/endpoint-creator`).
- `description`: la frase con cui l'agente decide **se e quando** caricare la skill. Una buona `description` produce un caricamento affidabile; una vaga rischia di non essere caricata quando serve o di essere caricata in contesti non rilevanti.

### Differenza pratica CLAUDE.md vs Skill

| | CLAUDE.md | Skill |
|---|---|---|
| Caricamento | sempre, a ogni sessione | on-demand, quando l'agente lo decide |
| Costo token | costante | pagato solo se serve |
| Granularità | regole macro del repo | procedura specifica (es. "creare un endpoint") |
| Numero per repo | di solito uno (al root) | molte |

## Hands-on

**Prima di iniziare**: scegli il linguaggio e prepara lo starter di questo modulo (`modules/M1-istruzioni/starters/<linguaggio>/`) come descritto nello [Step 3 del Setup](../../README.md#step-3---prepara-lo-starter-del-tuo-linguaggio). I test devono passare (2 test).

Lo starter è una piccola **Task API** in-memory con tre endpoint: `GET /tasks`, `POST /tasks`, `PATCH /tasks/:id`.

### Step 1 - Verifica che CLAUDE.md guidi l'agente

Apri il `CLAUDE.md` al root del repo e scorrilo: descrive stack, struttura della Task API, convenzioni di naming, formato degli errori, status code e il vincolo "ogni endpoint ha un test". Claude Code lo carica all'avvio della sessione, quindi segue questo contratto senza che tu glielo ripeta in chat.

In Claude Code (estensione o CLI, avviata dal root del repo) apri una **nuova conversazione** e chiedi (sostituisci `<linguaggio>`):

> Nel progetto `@modules/M1-istruzioni/starters/<linguaggio>` aggiungi un endpoint `PUT /tasks/:id` che sostituisce completamente un task esistente. Il body deve contenere `title` e `status`, e l'endpoint restituisce il task aggiornato.

Claude Code ti chiederà il permesso prima di modificare file o lanciare comandi: approva.

**Cosa osservare** nella risposta e nelle modifiche:
- la posizione del nuovo endpoint (nel file indicato da `CLAUDE.md` per il tuo linguaggio);
- la **validazione del body**: entrambi i campi sono obbligatori, perché `PUT` ha semantica *replace*;
- gli errori nel formato `{ "error": "<messaggio>" }` previsto da `CLAUDE.md`;
- i test aggiunti: almeno un happy path e un error case.

**Risultato atteso**: l'endpoint risponde `200` se il task esiste, `404` se l'id non esiste, `400` se il body è invalido, e i test (ora più di 2) passano. Se Claude non li ha eseguiti, lanciali tu dalla cartella dello starter.

L'agente ha seguito il contratto del repo *senza che tu lo abbia scritto in chat*: è `CLAUDE.md` che lo ha guidato.

### Step 2 - Crea una Skill e osserva il caricamento automatico

Crea il file `.claude/skills/endpoint-creator/SKILL.md` **al root del repository** (non dentro la cartella dello starter: Claude Code cerca le skill di progetto in `.claude/skills/` del workspace) con questo contenuto:

```markdown
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
```

**Checkpoint**: il file esiste in `<root del repo>/.claude/skills/endpoint-creator/SKILL.md`.

Ora apri una **nuova conversazione** (così Claude Code vede la skill appena creata) e chiedi, **senza nominare la skill**:

> Nel progetto `@modules/M1-istruzioni/starters/<linguaggio>` aggiungi un endpoint `DELETE /tasks/:id` che cancella un task esistente.

**Risultato atteso**:
- nella chat compare l'uso della skill `endpoint-creator` (Claude la carica da solo, perché il prompt corrisponde alla `description` *"Use when creating a new REST endpoint"*);
- l'endpoint risponde `204` senza body se il task esiste, `404` altrimenti, con un test per ciascun caso.

La skill si può anche invocare esplicitamente: digita `/` nel prompt e scegli `endpoint-creator`, ad esempio:

> /endpoint-creator aggiungi un endpoint `GET /tasks/:id` che restituisce un singolo task.

> **Se la skill non viene caricata**: verifica il percorso del file (deve essere al root, non nello starter), che il frontmatter sia tra due righe `---` e di aver aperto una nuova conversazione.

## Wrap

- `CLAUDE.md` = identità del repo, regole sempre vere, costo in token sempre presente.
- Skill = know-how procedurale, caricato on-demand quando la `description` corrisponde al task.
- Triage: la regola serve "sempre"? => `CLAUDE.md`. Serve "a volte"? => Skill.

## Problemi?

- Skill di riferimento: `modules/M1-istruzioni/solution/.claude/skills/endpoint-creator/SKILL.md`, da copiare in `.claude/skills/endpoint-creator/SKILL.md` al root del repo.
- Codice di riferimento con `PUT` e `DELETE`: `modules/M1-istruzioni/solution/<linguaggio>/`.

➡️ Prossimo modulo: [`../M2-capacita/README.md`](../M2-capacita/README.md)
