# Modulo M4 - Contesto & Memoria

> Obiettivo: governare **contesto e memoria** su sessioni lunghe e codebase grandi. Imparerai a tornare indietro nel tempo con i **checkpoints**, a far ricordare a Claude fatti di progetto tra una sessione e l'altra con le **memorie**, a esplorare il codice a basso costo di token con **tokensave**, e a recuperare il *perché* di vecchie decisioni con l'**episodic memory**.

> Concetti chiave: una sessione agentica accumula due cose che vanno gestite - lo **stato** (codice + conversazione, recuperabile) e la **conoscenza** (fatti e decisioni, da rendere persistenti). Checkpoint e memorie agiscono su questi due assi; tokensave ed episodic memory riducono il costo di ricostruire il contesto su codebase ed esperienza pregresse.

> Tutti i file di riferimento sono in `modules/M4-contesto-memoria/solution/.claude/`.

## Teoria

### Il problema: contesto finito, lavoro infinito

Una sessione di coding agentica è limitata da una context window finita, ma il lavoro reale dura più sessioni e copre codebase più grandi di quanto entri nel contesto. Da qui due esigenze distinte:

- **Recuperare lo stato** quando un esperimento va male o serve provare un'altra strada (senza perdere il punto di partenza).
- **Persistere la conoscenza** - convenzioni, decisioni, il *perché* - così che non vada ricostruita ogni volta da zero.

Claude Code offre quattro strumenti, ognuno su un asse diverso:

| Strumento | Asse | Cosa risolve | Persiste tra sessioni? |
| ----------------- | ----------------------- | ----------------------------------------------------- | ----------------------------- |
| **Checkpoints** | Stato (codice + chat) | Tornare indietro dentro una sessione | No |
| **Memorie** | Conoscenza distillata | Far ricordare fatti/convenzioni a ogni avvio | Sì (file persistenti) |
| **Tokensave** | Contesto del codice | Esplorare codebase grandi senza leggere interi file | N/A (indice ricostruibile) |
| **Episodic memory** | Conoscenza grezza (il *perché*) | Recuperare decisioni e trade-off da conversazioni passate | Sì (storico indicizzato) |

I primi due sono nativi di Claude Code; gli ultimi due sono estensioni (un server MCP e un plugin) già predisposte in questo ambiente. Li vediamo uno per uno nell'hands-on.

### Checkpoint vs Git vs memoria - non confonderli

È il punto che genera più equivoci, quindi mettiamolo subito in chiaro:

- Un **checkpoint** è un *undo di sessione*: ripristina codice e conversazione e non sostituisce git.
- **Git** è la storia permanente: commit, branch, collaborazione.
- Una **memoria** non ripristina nulla: è conoscenza che resta in contesto.

### Memorie: scope e meccanismi

Quando parliamo di "memoria" in Claude Code, intendiamo due scope e due meccanismi diversi.

**Scope:**

| Scope | Dove vive | Visibilità | Uso tipico |
| --------------- | ------------------------------------- | ---------------------------- | -------------------------------------- |
| **User-level** | nella home dell'utente (`~/.claude/`) | solo te, su tutti i progetti | preferenze personali di stile/workflow |
| **Project-level** | nel repo (committato in git) | tutto il team | convenzioni, contratti, vincoli del progetto |

**Meccanismi:**

- **`CLAUDE.md`** - il *contratto* del repo, già visto in M1. Sempre caricato in ogni sessione, committato, condiviso col team. È il modo project-level per definire la ground truth (stack, convenzioni, vincoli non negoziabili).
- **Auto Memory file-based** - fatti isolati e persistenti in file Markdown con frontmatter. Solo l'indice `MEMORY.md` (prime ~200 righe / 25KB) è caricato all'avvio; i singoli file di memoria sono letti **on-demand**, quando Claude ne ha bisogno. Costa quasi zero token a riposo.
- **Shortcut `#`** - durante una conversazione, prefissare un messaggio con `#` chiede a Claude di salvare quel fatto in memoria al volo, senza editare file a mano.

> **Attenzione! - Dove vive l'Auto Memory file-based.** I file di Auto Memory vivono in `~/.claude/projects/<project>/memory/`: questo path è **machine-local**, derivato dalla root del repo git ma **non versionato nel repo**. Quindi non puoi committarli per condividerli col team. Per la conoscenza condivisa nel repo il meccanismo giusto resta **`CLAUDE.md`** (o, in M3, l'iniezione via hook). Il seed che trovi in `modules/M4-contesto-memoria/solution/.claude/memory/` è perciò un **template di riferimento**: nell'hands-on lo **copi** nel path machine-local per attivarlo, e ne osservi il recall. Non aspettarti che "compaia" semplicemente perché hai clonato il repo.

Confronto dei tre meccanismi di conoscenza:

| Aspetto | Auto Memory (file-based) | CLAUDE.md | Skill |
| --------------- | ------------------------------------- | ----------------------------------- | --------------------------------- |
| Chi scrive | Claude + utente | Utente | Utente |
| Caricamento | indice `MEMORY.md` all'avvio; file on-demand | sempre, in ogni prompt | on-demand (trigger su `description`) |
| Costo token | minimale (solo l'indice a riposo) | costante (tutto il file) | pagato solo se invocata |
| Dove vive | machine-local (`~/.claude/projects/.../memory/`) | nel repo (committato) | nel repo (committato) |
| Scopo | fatti isolati, learning persistenti | contratto del repo | procedura ("come fare X") |

Regola pratica: la regola serve **sempre e a tutto il team**? => `CLAUDE.md`. È una **procedura** da caricare quando serve? => Skill (M1). È un **fatto isolato** che vuoi ti torni utile nelle tue sessioni future su questa macchina? => Auto Memory file-based.

### Tokensave: capire il codice senza leggerlo tutto

Su una codebase grande, per "capire" come è fatto qualcosa l'agente fa molte chiamate grezze - `grep`, `glob`, lettura di interi file - e ogni file letto consuma token di contesto. **Tokensave** è un server MCP 100% locale che ribalta il modello: indicizza **una volta** la codebase in un **knowledge graph** (simboli, relazioni di chiamata, metriche) salvato in `.tokensave/tokensave.db`, e poi risponde a **query strutturate** restituendo solo i punti d'ingresso, i simboli correlati e gli snippet pertinenti - non interi file. Indicizza una volta, interroga molte volte a basso costo.

### Episodic memory: recuperare il *perché*

Le memorie curate documentano *cosa* fa il progetto. Ma il *perché* di una decisione - le alternative scartate, i trade-off discussi, i vincoli del momento - vive nelle conversazioni, e di solito si perde. L'**episodic memory** è un plugin che indicizza localmente le tue conversazioni passate (embedding generati offline + ricerca semantica su SQLite) e ti permette di recuperarle. Non sostituisce le memorie curate: le **completa**.

| Aspetto | Episodic memory | Memorie curate (`MEMORY.md` + file) |
| ------------- | -------------------------------------------- | ---------------------------------------- |
| Sorgente | registrazione automatica di tutte le sessioni | fatti scritti e curati a mano |
| Scope | user-local, non condiviso | a tua scelta (qui: machine-local via seed) |
| Contenuto | conversazioni grezze: trade-off, alternative, *perché* | fatti distillati: convenzioni, contratti |
| Uso tipico | "come abbiamo deciso X la volta scorsa?" | "qual è il contratto della Task API?" |
| Indicizzazione | ricerca vettoriale + testo, automatica | edit manuale dei file |

## Hands-on

La codebase di lavoro è la **Task API** (CRUD in-memory) portata avanti dai moduli precedenti. Scegli il tuo linguaggio in `starters/dotnet`, `starters/typescript`, `starters/python`.

---

### Argomento 1 - Checkpoints (Rewind)

Nessun artefatto da creare: i checkpoint sono una feature di sessione. Claude Code crea **automaticamente** un checkpoint a ogni tuo prompt — non serve crearli a mano. Un checkpoint cattura le modifiche fatte dai **tool di editing** di Claude (`Edit`, `Write`, `MultiEdit`) e la **conversazione** fino a quel punto. Per **scegliere a quale checkpoint tornare** usi il comando `/rewind` (vedi Step 3): apre il menu dei checkpoint della sessione e lì selezioni il punto a cui ripristinare.

#### Step 1 - Punto di partenza sicuro

Apri Claude Code e verifica che i test passino - questo è lo stato a cui potrai tornare:

```bash
# .NET
cd modules/M4-contesto-memoria/starters/dotnet
dotnet test Tasks.Tests

# TypeScript
cd modules/M4-contesto-memoria/starters/typescript
npm install
npm test

# Python
cd modules/M4-contesto-memoria/starters/python
python3 -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest
```

#### Step 2 - Un prompt ambizioso

Nel pannello Claude Code, invia:

> Nel progetto `@modules/M4-contesto-memoria/starters/<linguaggio>` voglio migliorare la Task API aggiungendo una ricerca per titolo (case-insensitive), con un nuovo endpoint `GET /tasks/search?q=<query>`. Implementalo con test.

Claude modifica più file (store, route, test). A fine prompt Claude Code crea automaticamente un nuovo checkpoint. Lancia di nuovo il comando di test per vedere lo stato della feature (che passi o fallisca, va bene: serve solo per dimostrare il rewind).

#### Step 3 - Torna indietro con `/rewind`

Premi due volte **`Esc`** oppure digita **`/rewind`**. Si apre un menu scrollabile con la lista dei prompt inviati nella sessione. Per il checkpoint scelto, le opzioni sono:

1. **Restore code and conversation** - ripristina codice e conversazione (cancella tutto ciò che viene dopo)
2. **Restore conversation** - torna al messaggio scelto mantenendo il codice attuale
3. **Restore code** - ripristina il codice mantenendo la conversazione attuale
4. **Summarize from here** / **Summarize up to here** - comprimono parte della conversazione in un summary, **senza toccare i file su disco**

Seleziona il checkpoint **prima** della richiesta di ricerca e scegli **"Restore code"**: i file tornano allo stato iniziale, ma la conversazione resta integra preservando quindi il contesto.

#### Verifica

- `Esc Esc` apre un menu con almeno 2-3 checkpoint della sessione.
- Dopo **"Restore code"**, rilanciando i test tutti passano come all'inizio.
- La conversazione è intatta: vedi ancora il prompt originale nel menu e nel campo input.
- **Limite chiave da osservare**: se avessi cancellato un file con un comando bash (`rm`, `mv`, `git checkout`), quel cambiamento **non** sarebbe stato reversibile. Il checkpoint traccia solo gli edit dei tool di Claude, non ciò che tocca la shell.

---

### Argomento 2 - Memorie

Crei un seed di memorie di progetto sulla Task API e verifichi che Claude le ricordi in una nuova sessione. Come spiegato in Teoria, l'Auto Memory file-based vive in un path **machine-local**: il seed committato è un template che copi lì per attivarlo.

#### Step 1 - Individua il path machine-local

Le memorie file-based di questo repo vivono in `~/.claude/projects/<project>/memory/`, dove `<project>` deriva dalla root del repo git. Crea la directory:

```bash
mkdir -p ~/.claude/projects/<project>/memory
```

> Se non sei sicuro del nome `<project>` derivato: avvia una sessione e chiedi a Claude *"qual è il path della tua directory di memoria per questo progetto?"* - usa quel path.

#### Step 2 - Copia il seed

Il seed di riferimento è in `modules/M4-contesto-memoria/solution/.claude/memory/` e contiene quattro file:

- `MEMORY.md` - l'indice (una riga di link per memoria)
- `task-api-validation.md` - formato dell'errore 400 e regole di validazione per verbo
- `naming-conventions.md` - kebab-case negli endpoint, payload camelCase, record immutabili
- `status-codes-and-responses.md` - status code per operazione, header `Location` su 201

Copiali nel path machine-local:

```bash
cp modules/M4-contesto-memoria/solution/.claude/memory/* ~/.claude/projects/<project>/memory/
```

Apri uno dei file e nota il frontmatter YAML obbligatorio:

```yaml
---
name: task-api-validation
description: 400 error format and validation rules for Task API endpoints
metadata:
  type: project
---
```

- `name`: identificatore tecnico in kebab-case, unico.
- `description`: la riga con cui Claude decide se la memoria è **rilevante** per il task corrente (analoga alla `description` di una skill).
- `metadata.type`: `user` (fatto su chi lavora), `feedback` (guida su come lavorare), `project` (vincoli/decisioni di progetto), `reference` (puntatore a risorsa esterna).

Nel corpo, i link `[[altro-name]]` collegano memorie correlate. L'indice `MEMORY.md` ha una riga per memoria:

```markdown
- [Task API Validation Rules](task-api-validation.md) - 400 error format, required/optional fields per verb
```

#### Step 3 - Verifica il recall in una nuova sessione

Chiudi la sessione (o `/clear`) e aprine una nuova nel workspace. Chiedi:

> Quali file di memoria di progetto hai per questo repo? Quali status code devo usare per un endpoint `PUT /tasks/:id`? Qual è il formato del body di un errore 400 nella Task API?

> In alternativa, per aggiungere un fatto al volo senza editare file, prova lo shortcut `#`: invia un messaggio come `# La Task API usa uno store in-memory, niente DB reale` e Claude lo salverà in memoria.

---

### Argomento 3 - Tokensave (https://github.com/aovestdipaperino/tokensave/)

> **Attenzione!** La Task API è una codebase piccola, semplice un `Read` diretto costa pochi token e il risparmio reale è modesto. Tokensave brilla su repo da migliaia di file. Il valore che porti a casa da questo esercizio non è il numero di token salvati ora, ma il **pattern**: query strutturata invece di scansione grezza, e la regola tokensave-first.

> **Prerequisito.** Nel Codespace il devcontainer ha già fatto due dei tre passi di [tokensave.dev](https://tokensave.dev/): ha **installato il binario** e ha eseguito **`tokensave install`** (che registra il server MCP nel config utente `~/.claude.json` — **non** nel `.mcp.json` del repo — e aggiunge le prompt rules tokensave-first). Quindi il server dovrebbe essere già disponibile. Se lavori **in locale senza devcontainer** rifai a mano quei due passi — è un binario Rust nativo, non npm/pip:
> ```bash
> cargo install tokensave                        # 1) installa il binario (qualsiasi piattaforma)
> brew install aovestdipaperino/tap/tokensave    #    oppure, su macOS
> tokensave install                              # 2) registra il server MCP + prompt rules (una volta)
> ```
> Il terzo passo (`tokensave init`) è l'esercizio qui sotto.

#### Step 1 - Inizializza l'indice

Dalla root del workspace:

```bash
tokensave init
```

`init` è un opt-in una-tantum per progetto: indicizza la codebase la prima volta. Dopo le modifiche, l'aggiornamento incrementale è `tokensave sync`.

**Verifica:**
- Esiste `.tokensave/tokensave.db`.
- `.tokensave/` è già in `.gitignore` (il DB è ricostruibile, non si committa).
- Chiedi a Claude di eseguire il tool MCP `tokensave_status`: deve mostrare numero di file/simboli indicizzati e i token risparmiati.

#### Step 2 - Esplora con una query strutturata

Nel pannello Claude Code (modalità Agent), fai una domanda di comprensione del codice **senza** far leggere i file grezzi:

> Usando tokensave, dimmi come è strutturato l'endpoint che crea un task nel progetto `@modules/M4-contesto-memoria/starters/<linguaggio>`: dove sono definite le route, quale store usano e come viene validato l'input. Non leggere i file grezzi.

Claude dovrebbe chiamare `tokensave_context` (e magari `tokensave_search` o `tokensave_callees`) e rispondere citando i simboli reali del tuo starter (la funzione delle route, lo store in-memory, la validazione che ritorna 400).

**Verifica:**
- Nel flusso dei tool call compare un tool `tokensave_*` **prima** di eventuali `Read`/grep.
- La risposta nomina simboli/file realmente esistenti nel tuo starter.
- Su questa codebase piccola la differenza di costo è modesta

Nota: è `tokensave install` (il passo 2 del prerequisito, già eseguito dal devcontainer) ad aggiungere al file utente CLAUDE.md le istruzioni che dicono a Claude di usare tokensave prima di `Read`/grep o agenti di esplorazione.
---

### Argomento 4 - Episodic memory

Recuperi una decisione presa in M1-M3 da conversazioni passate e la confronti con le memorie curate.

> **Attenzione!.** L'episodic memory ha bisogno di uno **storico**: indicizza le tue sessioni passate. Lo scenario funziona se hai **attivato il plugin all'inizio** (idealmente prima di M1 — vedi la sezione di setup nel [README principale](../../README.md)) e hai svolto M1-M3 in sessioni precedenti **su questa macchina**, così quelle conversazioni risultano già indicizzate.

#### Step 1 - Installa il plugin

In Claude Code:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install episodic-memory@superpowers-marketplace
```

Il plugin registra **automaticamente** un hook `SessionStart` che esegue `episodic-memory sync`: archivia e indicizza le nuove conversazioni. Nessuna attivazione manuale necessaria.

**Verifica:**
- In Settings → Plugins compare `episodic-memory`.
- `/hooks` mostra un `SessionStart` registrato dal plugin.

> Nota: il sync indicizza le conversazioni di una sessione **dopo** che è terminata. Per cercare contenuti della sessione appena finita, devi prima avviarne una nuova.

#### Step 2 - Cerca una decisione passata

Chiedi a Claude (skill `remembering-conversations`, o subagente `@episodic-memory:search-conversations`):

> Usando l'episodic memory, recupera: nelle sessioni precedenti su questo progetto, quale logica di validazione abbiamo discusso per gli endpoint della Task API? Quali alternative o trade-off avevamo considerato?

Claude lancia la ricerca semantica sulle conversazioni passate e restituisce estratti con session ID, timestamp e il razionale della decisione.

**Verifica:**
- I risultati includono snippet da conversazioni passate (con metadati).
- Se hai svolto M1-M3 in sessioni precedenti, i risultati referenziano quelle decisioni.
- Se il vault è vuoto (ambiente fresco), la ricerca torna "nessuna conversazione trovata": atteso, prosegui allo Step 3.

#### Step 3 - Confronta con la memoria curata

Chiedi:

> Ora apri `~/.claude/projects/<project>/memory/MEMORY.md` e confronta: quali fatti sono documentati lì rispetto a quanto recuperato dall'episodic memory?

Osserva la differenza di natura: le memorie curate definiscono la **ground truth** (cosa fa il progetto, contratti, convenzioni); l'episodic memory recupera il **come e il perché** (alternative esplorate, edge case dibattuti, vincoli del momento).

## Wrap

- **Checkpoints**: undo di sessione (`/rewind` o `Esc Esc`) su edit dei tool + conversazione. Non traccia i comandi bash, retention 30gg, non sostituisce git.
- **Memorie**: l'Auto Memory file-based è machine-local (`~/.claude/projects/<project>/memory/`); per conoscenza condivisa col team usi `CLAUDE.md`. Indice `MEMORY.md` all'avvio, topic file on-demand, shortcut `#` per salvare al volo.
- **Tokensave**: indicizza una volta, interroga molte; la regola **tokensave-first** è l'apprendimento trasferibile, il valore in token scala con la dimensione della codebase.
- **Episodic memory**: ricerca semantica locale sulle conversazioni passate, preserva il *perché*. Completa (non sostituisce) le memorie curate; serve uno storico per essere utile.

## Problemi?

Se ti blocchi: `modules/M4-contesto-memoria/solution/` contiene la Task API allo stato finale e, in `solution/.claude/memory/`, il seed di memorie di riferimento da copiare nel path machine-local.

➡️ Prossimo modulo: [`../M5-distribuzione/README.md`](../M5-distribuzione/README.md)
