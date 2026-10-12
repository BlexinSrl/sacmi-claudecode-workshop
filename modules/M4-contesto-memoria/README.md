# Modulo M4 - Contesto & Memoria · Checkpoints, Memorie, Tokensave, Episodic memory

> Obiettivo: gestire **contesto e memoria** su sessioni lunghe e codebase grandi. Imparerai a tornare indietro con i **checkpoints**, a far ricordare a Claude fatti di progetto tra una sessione e l'altra con le **memorie**, a esplorare il codice spendendo pochi token con **tokensave** e a recuperare il *perché* di vecchie decisioni con l'**episodic memory**.

## Teoria

### Il problema: contesto finito, lavoro infinito

Una sessione di Claude Code ha una context window finita, ma il lavoro reale dura più sessioni e riguarda codebase più grandi di quanto entri nel contesto. Da qui due esigenze distinte:

- **Recuperare lo stato** quando un esperimento va male, senza perdere il punto di partenza.
- **Rendere persistente la conoscenza** (convenzioni, decisioni, il *perché*), così che non vada ricostruita ogni volta.

In questo modulo vediamo quattro strumenti, ognuno su un asse diverso:

| Strumento | Asse | Cosa risolve | Persiste tra sessioni? |
| --- | --- | --- | --- |
| **Checkpoints** | Stato (codice + chat) | Tornare indietro dentro una sessione | No (legati alla sessione) |
| **Memorie** | Conoscenza distillata | Far ricordare fatti e convenzioni a ogni avvio | Sì (file Markdown) |
| **Tokensave** | Contesto del codice | Esplorare codebase grandi senza leggere interi file | Sì (indice locale ricostruibile) |
| **Episodic memory** | Conoscenza grezza (il *perché*) | Recuperare decisioni da conversazioni passate | Sì (storico indicizzato) |

I primi due sono funzioni native di Claude Code; gli altri due sono estensioni (un server MCP e un plugin) che hai installato nel [Setup](../../README.md#setup).

### Checkpoint, git e memoria: non confonderli

- Un **checkpoint** è un *undo di sessione*: ripristina il codice modificato da Claude e/o la conversazione. Non sostituisce git.
- **Git** è la storia permanente: commit, branch, collaborazione.
- Una **memoria** non ripristina nulla: è conoscenza che torna nel contesto nelle sessioni successive.

### Memorie: CLAUDE.md e Auto Memory

Claude Code ha due meccanismi complementari per portare conoscenza da una sessione all'altra:

- **`CLAUDE.md`**: le istruzioni che scrivi tu, già viste in M1. Sempre caricato, committato nel repo, condiviso col team. Esiste anche a livello utente (`~/.claude/CLAUDE.md`) per le preferenze personali valide su tutti i progetti.
- **Auto Memory**: appunti che Claude salva da solo (o quando gli chiedi *"ricorda che..."*) in file Markdown con frontmatter. All'avvio viene caricato solo l'indice `MEMORY.md` (le prime 200 righe o 25KB); i singoli file vengono letti quando servono. È attiva di default: puoi verificarla e gestirla con `/memory`.

> ⚠️ **Dove vive l'Auto Memory.** I file di Auto Memory stanno in `~/.claude/projects/<project>/memory/`, dove `<project>` deriva dal percorso del repo git. È una cartella **locale alla tua macchina, non versionata nel repo**: non puoi committarla per condividerla col team. Per la conoscenza condivisa il meccanismo giusto resta `CLAUDE.md` (o, come in M3, l'iniezione via hook).
>
> Il seed in `modules/M4-contesto-memoria/solution/.claude/memory/` è quindi un **template**: nell'hands-on lo copi nella cartella locale per attivarlo.

Confronto dei tre meccanismi di conoscenza visti finora:

| Aspetto | Auto Memory | CLAUDE.md | Skill |
| --- | --- | --- | --- |
| Chi scrive | Claude (e tu) | Tu | Tu |
| Caricamento | indice `MEMORY.md` all'avvio, file on-demand | sempre, a ogni sessione | on-demand (in base alla `description`) |
| Costo token | minimo a riposo (solo l'indice) | costante (tutto il file) | pagato solo se caricata |
| Dove vive | `~/.claude/projects/<project>/memory/` (locale) | nel repo (committato) | nel repo (committato) |
| Scopo | fatti isolati, cose imparate | contratto del repo | procedura ("come fare X") |

Regola pratica: la regola serve **sempre e a tutto il team**? => `CLAUDE.md`. È una **procedura** da caricare quando serve? => Skill. È un **fatto** che ti torna utile nelle tue sessioni future su questa macchina? => Auto Memory.

### Tokensave: capire il codice senza leggerlo tutto

Per capire come è fatto qualcosa, l'agente di solito fa molte chiamate "grezze" (`grep`, ricerca di file, lettura di interi file) e ogni file letto consuma contesto. **Tokensave** è un server MCP locale che cambia approccio: indicizza **una volta** la codebase in un grafo di simboli e relazioni (salvato in `.tokensave/`) e poi risponde a **query strutturate** restituendo solo i simboli e gli snippet pertinenti, non file interi.

### Episodic memory: recuperare il *perché*

Le memorie curate dicono *cosa* vale nel progetto. Il *perché* di una decisione (alternative scartate, trade-off, vincoli del momento) vive nelle conversazioni e di solito si perde. **Episodic memory** è un plugin che indicizza localmente le tue conversazioni passate con Claude Code e ti permette di cercarle per significato. Non sostituisce le memorie di Claude Code, le **completa**.

| Aspetto | Episodic memory | Memorie curate (`MEMORY.md` + file) |
| --- | --- | --- |
| Sorgente | tutte le sessioni, registrate automaticamente | fatti scritti e selezionati |
| Contenuto | conversazioni grezze: trade-off, alternative, *perché* | fatti distillati: convenzioni, contratti |
| Uso tipico | "come avevamo deciso X la volta scorsa?" | "qual è il contratto della Task API?" |

## Hands-on

**Prima di iniziare**: prepara lo starter di questo modulo (`modules/M4-contesto-memoria/starters/<linguaggio>/`) come descritto nello [Step 3 del Setup](../../README.md#step-3---prepara-lo-starter-del-tuo-linguaggio). I test devono passare (6 test).

I quattro argomenti sono indipendenti: puoi svolgerli nell'ordine proposto.

---

### Argomento 1 - Checkpoints

Non c'è nulla da creare: Claude Code crea **automaticamente** un checkpoint a ogni prompt che invii. Il checkpoint cattura le modifiche fatte dagli strumenti di editing di Claude e la conversazione fino a quel punto.

#### Step 1 - Punto di partenza

Verifica che i test dello starter passino (6 test): è lo stato a cui tornerai.

#### Step 2 - Un prompt che modifica più file

Apri una nuova conversazione e invia il seguente prompt:

> Nel progetto `@modules/M4-contesto-memoria/starters/<linguaggio>` aggiungi una ricerca per titolo (case-insensitive) con un nuovo endpoint `GET /tasks/search?q=<query>`. Implementalo con i test.

Claude modifica più file (store, route, test). Rilancia i test: che passino o no non importa, serve solo avere delle modifiche da annullare.

**Checkpoint**: con `git status` (dal root del repo) vedi i file modificati nello starter.

#### Step 3 - Torna indietro

**Nell'estensione VS Code**: passa il mouse sul messaggio con cui hai chiesto la ricerca, clicca il pulsante di rewind e scegli **Rewind code to here**. Le altre opzioni sono **Fork conversation from here** (nuova conversazione, codice invariato) e **Fork conversation and rewind code**.

**Nella CLI** (`claude` nel terminale): premi due volte `Esc` con il prompt vuoto, oppure digita `/rewind`. Scegli il messaggio e poi una delle azioni: **Restore code and conversation**, **Restore conversation**, **Restore code**, **Summarize from here**, **Summarize up to here**. Per questo esercizio usa **Restore code and conversation**.

**Risultato atteso**:
- `git status` non mostra più le modifiche dello starter;
- rilanciando i test passano di nuovo i 6 test iniziali;
- la conversazione è ancora lì: Claude ricorda cosa avevi chiesto, quindi puoi chiedergli un approccio diverso senza rispiegare tutto.

> **Limite da ricordare**: i checkpoint tracciano solo le modifiche fatte dagli strumenti di editing di Claude. File cancellati o spostati con comandi da terminale (`rm`, `mv`, `git checkout`) **non** vengono ripristinati. Anche le modifiche fatte da un subagent, in genere, non vengono ripristinate.

---

### Argomento 2 - Memorie

Attivi un seed di memorie di progetto sulla Task API e verifichi che Claude le ricordi in una nuova sessione.

#### Step 1 - Trova la cartella delle memorie

Il modo più semplice: in Claude Code digita `/memory` e scegli l'opzione per aprire la cartella dell'Auto Memory. In quel menu verifica anche che l'Auto Memory sia attiva.

In alternativa calcola il percorso da terminale, dal root del repo:

```bash
# macOS / Linux
MEM_DIR="$HOME/.claude/projects/$(git rev-parse --show-toplevel | sed 's/[^A-Za-z0-9]/-/g')/memory"
echo "$MEM_DIR"
```

```powershell
# Windows (PowerShell)
$MEM_DIR = "$HOME\.claude\projects\" + ((git rev-parse --show-toplevel) -replace '[^A-Za-z0-9]','-') + "\memory"
$MEM_DIR
```

> Se il percorso calcolato non corrisponde a una cartella esistente in `~/.claude/projects/`, chiedi a Claude: *"qual è il percorso della tua cartella di Auto Memory per questo progetto?"* e usa quello.

#### Step 2 - Copia il seed

Il seed in `modules/M4-contesto-memoria/solution/.claude/memory/` contiene quattro file:

- `MEMORY.md`: l'indice, una riga con link per ogni memoria;
- `task-api-validation.md`: formato dell'errore 400 e regole di validazione per verbo;
- `naming-conventions.md`: path kebab-case, `TaskItem` immutabile, store in-memory;
- `status-codes-and-responses.md`: status code per operazione, header `Location` sul 201.

Copia i file nella cartella delle memorie. Nel file MEMORY.md le informazioni devono essere **accodate** e non sovrascritte, perché durante M1-M3 Claude potrebbe aver già salvato delle memorie sue.

Apri uno dei file copiati e osserva il frontmatter:

```yaml
---
name: task-api-validation
description: 400 error format and validation rules for Task API endpoints
metadata:
  type: project
---
```

- `name`: identificatore in kebab-case, unico.
- `description`: la riga con cui Claude decide se la memoria è **rilevante** per il task corrente (come la `description` di una skill).
- `metadata.type`: `user` (chi sei), `feedback` (come preferisci che Claude lavori), `project` (vincoli e decisioni di progetto), `reference` (puntatore a una risorsa esterna).

Nel corpo, i link `[[altro-name]]` collegano memorie correlate.

**Checkpoint**: nella cartella delle memorie ci sono i tre file e `MEMORY.md` contiene le tre righe del seed.

#### Step 3 - Verifica il recall in una nuova sessione

Apri una **nuova conversazione** e chiedi:

> Quali memorie di progetto hai per questo repo? Quali status code devo usare per un endpoint `PUT /tasks/:id`? Qual è il formato del body di un errore 400 nella Task API?

**Risultato atteso**: Claude elenca le memorie del seed e risponde `200` (successo), `404` (id inesistente), `400` (body invalido) e `{ "error": "<messaggio>" }`, citando le memorie (nell'interfaccia può comparire un'indicazione del tipo *"Recalled N memories"*).

Per aggiungere un fatto al volo senza modificare file a mano, chiediglielo esplicitamente:

> Ricorda che la Task API usa uno store in-memory e non deve mai usare un DB reale.

**Risultato atteso**: Claude conferma il salvataggio e nella cartella delle memorie compare un nuovo file (o una nuova riga in `MEMORY.md`).

---

### Argomento 3 - Tokensave

> **Nota**: la Task API è una codebase piccola, quindi leggere un file costa pochi token e il risparmio è modesto. Tokensave rende al massimo su repository con migliaia di file. Quello che ti porti a casa è il **metodo**: query strutturata invece di lettura grezza.

**Prerequisito**: `tokensave install --agent claude` eseguito nel [Setup, Step 5](../../README.md#step-5---registra-tokensave-per-m4). Verifica con `/mcp`: deve comparire il server `tokensave`.

#### Step 1 - Indicizza il progetto

Dal **root del repo**:

```bash
tokensave init
```

`init` indicizza la codebase la prima volta (una tantum per progetto). Dopo le modifiche, l'aggiornamento incrementale si fa con `tokensave sync`.

**Risultato atteso**:
- esiste la cartella `.tokensave/` al root del repo;
- `.tokensave/` è già in `.gitignore` (l'indice è locale e ricostruibile, non si committa);
- `tokensave status` mostra il numero di file e simboli indicizzati.

#### Step 2 - Esplora con una query strutturata

Apri una **nuova conversazione** e chiedi:

> Usando tokensave, dimmi come è strutturato l'endpoint che crea un task nel progetto `modules/M4-contesto-memoria/starters/<linguaggio>`: dove sono definite le route, quale store usano e come viene validato l'input. Non leggere i file per intero.

**Risultato atteso**:
- nel flusso dei tool compare un tool `tokensave_*` (es. `tokensave_context` o `tokensave_search`) **prima** di eventuali letture di file;
- la risposta cita simboli e file che esistono davvero nel tuo starter (la funzione delle route, `TaskStore`, la validazione che restituisce 400).

Nota: `tokensave install` ha aggiunto alla tua configurazione utente di Claude Code anche delle regole che chiedono a Claude di usare tokensave prima di `grep`, lettura di file o subagent di esplorazione. Per questo, da ora in poi, Claude tenderà a usarlo anche senza che tu lo chieda.

---

### Argomento 4 - Episodic memory

Recuperi una decisione presa in M1-M3 dalle conversazioni passate e la confronti con le memorie curate.

> **Nota**: l'episodic memory ha bisogno di uno **storico**. L'esercizio dà risultati utili se hai installato il plugin nel [Setup, Step 6](../../README.md#step-6---installa-il-plugin-episodic-memory-consigliato-per-m4) e hai svolto M1-M3 su questa macchina. Se lo installi solo ora, la ricerca troverà poco o nulla: è normale.

#### Step 1 - Verifica il plugin

Da terminale:

```bash
claude plugin list
```

**Risultato atteso**: compare `episodic-memory@superpowers-marketplace` abilitato. Se manca, installalo come nel Setup, Step 6, e apri una nuova conversazione.

Il plugin registra da solo un hook `SessionStart` che, a ogni avvio di sessione, archivia e indicizza le conversazioni nuove. Puoi vederlo con `/hooks`.

> Le conversazioni vengono indicizzate all'avvio della sessione **successiva**: per trovare i contenuti della sessione appena chiusa, aprine prima una nuova.

#### Step 2 - Cerca una decisione passata

Apri una nuova conversazione e chiedi:

> Usando episodic memory, cerca nelle sessioni precedenti su questo progetto: quale logica di validazione abbiamo discusso per gli endpoint della Task API (per esempio per `PUT /tasks/:id`)? Quali alternative o trade-off avevamo considerato?

**Risultato atteso**:
- Claude usa gli strumenti dell'episodic memory (tool `search` del plugin o il subagent `episodic-memory:search-conversations`);
- se hai svolto M1-M3 su questa macchina, i risultati riportano estratti di quelle conversazioni (con data e progetto);
- se lo storico è vuoto, la ricerca non trova conversazioni: atteso, passa allo Step 3.

#### Step 3 - Confronta con la memoria di Claude Code (auto memory)

Chiedi:

> Confronta il contenuto delle memorie di progetto (`MEMORY.md` e i file collegati) con quanto recuperato dall'episodic memory: quali informazioni ci sono solo da una parte?

**Cosa osservare**: le memorie curate contengono la **regola** (cosa fa il progetto, contratti, convenzioni); l'episodic memory restituisce il **come e il perché** (alternative esplorate, casi limite discussi, vincoli del momento).

## Wrap

- **Checkpoints**: undo di sessione sulle modifiche di Claude e sulla conversazione (pulsante rewind in VS Code, `/rewind` o `Esc Esc` nella CLI). Non tracciano i comandi da terminale e non sostituiscono git.
- **Memorie**: `CLAUDE.md` per la conoscenza condivisa col team; Auto Memory (`~/.claude/projects/<project>/memory/`) per i fatti locali. Indice `MEMORY.md` all'avvio, file on-demand, *"ricorda che..."* per salvare al volo.
- **Tokensave**: indicizza una volta, interroga molte volte; il risparmio cresce con la dimensione della codebase.
- **Episodic memory**: ricerca locale sulle conversazioni passate, conserva il *perché*. Completa le memorie curate e serve uno storico per essere utile.

## Problemi?

- **Il rewind non ripristina i file**: verifica di aver scelto *Rewind code to here* (VS Code) o *Restore code* (CLI) sul messaggio giusto. Le modifiche fatte da comandi di terminale non sono ripristinabili: usa `git restore <file>`.
- **Claude non cita le memorie**: controlla con `/memory` che l'Auto Memory sia attiva e che i file siano nella cartella giusta, poi apri una nuova conversazione.
- **`tokensave` non compare in `/mcp`**: riesegui `tokensave install --agent claude` e apri una nuova conversazione (se serve, riavvia VS Code o la CLI). `tokensave doctor` controlla installazione e configurazione.
- **Riferimenti**: `modules/M4-contesto-memoria/solution/<linguaggio>/` contiene la Task API di riferimento; `solution/.claude/memory/` il seed di memorie.

➡️ Prossimo modulo: [`../M5-distribuzione/README.md`](../M5-distribuzione/README.md)
