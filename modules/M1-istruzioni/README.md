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

Lo starter è una piccola **Task API** in-memory con tre endpoint: `GET /tasks`, `POST /tasks`, `PATCH /tasks/:id`. In questo modulo prima osservi l'effetto di `CLAUDE.md` (Step 1-2), poi usi una skill per aggiungere due endpoint (Step 3).

### Step 1 - Senza istruzioni: Claude va a intuito

Apri il `CLAUDE.md` al root del repo e scorrilo: descrive scopo del repo, stack, struttura della Task API e vincoli. La sezione `## Comandi`, però, dice solo da quale cartella lanciare i comandi: **non** dice quali comandi usare per ogni linguaggio.

In Claude Code (estensione o CLI, avviata dal root del repo) apri una **nuova conversazione** e chiedi (sostituisci `<linguaggio>`):

> Esegui i test dello starter di M1 in `<linguaggio>` e dimmi quanti passano.

Approva i comandi quando Claude chiede il permesso.

**Cosa osservare**: quali comandi sceglie Claude e da quale cartella. Non avendo istruzioni, deve **indovinare** in base a euristiche (i file che trova, le convenzioni più diffuse). Annota i comandi che ha eseguito: ti serviranno per il confronto. Alcuni esempi di cosa può succedere:
- **.NET**: lancia `dotnet test` senza indicare il progetto. In questo repo il comando prende la web app (`TaskApi.csproj`), che non ha test, ed esce con successo **senza eseguire nessun test**: un falso verde. Oppure se ne accorge, ma solo dopo qualche tentativo;
- **Python**: lancia `pytest` senza attivare il venv, oppure installa le dipendenze in modo diverso da come fa il team;
- **TypeScript**: di solito indovina (`npm test`), ma deve prima leggere `package.json` per capirlo.

### Step 2 - Con le istruzioni: Claude segue il contratto del repo

Ora dai a Claude le informazioni che mancavano. Apri `CLAUDE.md` e incolla questo blocco **subito sotto il paragrafo della sezione `## Comandi`** (prima di `## Convenzioni cross-linguaggio`):

````markdown
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
npm test                                     # vitest run - tutti i test
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
````

Salva il file, apri una **nuova conversazione** (`CLAUDE.md` viene letto all'avvio della conversazione) e rifai la stessa domanda:

> Esegui i test dello starter di M1 in `<linguaggio>` e dimmi quanti passano.

**Risultato atteso**: Claude va diretto alla cartella giusta e usa esattamente i comandi scritti in `CLAUDE.md` (`dotnet test Tasks.Tests`, il venv con `pytest`, `npm test`), senza tentativi. La risposta è **2 test passati**.

Confronta con i comandi annotati allo Step 1: la differenza è tutta nelle righe che hai aggiunto. È l'uso più tipico di `CLAUDE.md`: dire all'agente quello che **non può ricavare dal codice** (come si compila e si testa, le trappole note, i vincoli del team), una volta sola e per tutte le sessioni.

> **Se allo Step 1 Claude ha già usato i comandi giusti**: può capitare, le euristiche a volte funzionano (soprattutto con TypeScript). Il punto non cambia: con `CLAUDE.md` il comportamento è **garantito e ripetibile** invece che lasciato al caso. Controlla anche di aver aperto una nuova conversazione: nella stessa conversazione Claude ricorda cosa ha già fatto. Anche l'Auto Memory (la vedrai in M4) può falsare il confronto, se allo Step 1 Claude ha salvato cosa ha imparato.

### Step 3 - Crea una Skill e osserva il caricamento automatico

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

> /endpoint-creator aggiungi un endpoint `PUT /tasks/:id` che sostituisce completamente un task esistente. Il body deve contenere `title` e `status`.

**Risultato atteso**: `200` con il task aggiornato, `404` se l'id non esiste, `400` se manca uno dei due campi (con `PUT` sono entrambi obbligatori, perché sostituisce il task per intero). Alla fine i test dello starter passano tutti.

> **Se la skill non viene caricata**: verifica il percorso del file (deve essere al root, non nello starter), che il frontmatter sia tra due righe `---` e di aver aperto una nuova conversazione.

## Wrap

- `CLAUDE.md` = come si lavora nel repo (comandi, trappole note, vincoli): quello che l'agente non può ricavare dal codice. Sempre caricato, costo in token sempre presente.
- Skill = know-how procedurale, caricato on-demand quando la `description` corrisponde al task.
- Triage: la regola serve "sempre"? => `CLAUDE.md`. Serve "a volte"? => Skill.

## Problemi?

- **Allo Step 2 Claude non usa i comandi del blocco**: verifica di averlo incollato in `CLAUDE.md` al **root** del repo, sotto `## Comandi`, con tutti i blocchi di codice chiusi da ```` ``` ````, e di aver aperto una nuova conversazione.
- Skill di riferimento: `modules/M1-istruzioni/solution/.claude/skills/endpoint-creator/SKILL.md`, da copiare in `.claude/skills/endpoint-creator/SKILL.md` al root del repo.
- Codice di riferimento con `PUT` e `DELETE`: `modules/M1-istruzioni/solution/<linguaggio>/`.

➡️ Prossimo modulo: [`../M2-capacita/README.md`](../M2-capacita/README.md)
