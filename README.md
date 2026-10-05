# Claude Code Workshop

> Workshop hands-on su CLAUDE.md, Skills, Subagents, MCP, Hooks, Checkpoints, Memorie, Tokensave, Episodic memory, Plugins & Marketplace.

Il workshop si segue con **Claude Code** su un ambiente locale, a scelta tra l'**estensione per VS Code** e la **CLI** (`claude` nel terminale). Le due interfacce sono equivalenti: dove differiscono, i moduli indicano entrambe le strade (vedi [Estensione VS Code o CLI](#estensione-vs-code-o-cli)). Concetti, prompt ed esercizi sono **identici** per i tre linguaggi di starter (.NET 10, TypeScript, Python): scegli un linguaggio all'inizio e usa sempre quello. Tutte le customizations che creerai (skill, subagent, hook) vivono in `.claude/` al **root del repository**.

## Percorso

| Modulo | Argomento | Cosa crei |
|---|---|---|
| [M1 - Istruzioni](modules/M1-istruzioni/README.md) | CLAUDE.md + Skills | `.claude/skills/endpoint-creator/SKILL.md` |
| [M2 - Capacità](modules/M2-capacita/README.md) | Subagents + MCP | `.claude/agents/code-reviewer.md` |
| [M3 - Governance](modules/M3-governance/README.md) | Hooks (iniezione di contesto) | subagent `dba` + hook `SubagentStart` |
| [M4 - Contesto & Memoria](modules/M4-contesto-memoria/README.md) | Checkpoints, Memorie, Tokensave, Episodic memory | nessun file nel repo (feature di sessione e strumenti locali) |
| [M5 - Distribuzione](modules/M5-distribuzione/README.md) | Plugins & Marketplace | un repo marketplace separato con il plugin `workshop-dev-kit` |

Ogni modulo ha la stessa struttura: **Teoria** => **Hands-on** (step numerati con *Risultato atteso*) => **Wrap** => **Problemi?**.

## Prerequisiti

Il workshop assume che questi strumenti siano già installati. Verificali prima di iniziare:

| Strumento | Perché serve | Verifica |
|---|---|---|
| Git | clonare il repo, M5 | `git --version` |
| Account Anthropic attivo | tutti i moduli | login al primo avvio di Claude Code |
| **Claude Code CLI** (`claude`) | tutti i moduli se usi la CLI; comandi `claude plugin ...` in M4/M5 anche se usi l'estensione | `claude --version` |
| VS Code (≥ 1.94) + estensione **Claude Code** | solo se segui il workshop dall'estensione | icona ✱ (Spark) in alto a destra dell'editor |
| Node.js 20+ | starter TypeScript **e** plugin episodic-memory (M4) | `node --version` |
| .NET 10 SDK **oppure** Python 3.11+ | solo se scegli lo starter .NET o Python | `dotnet --version` / `python3 --version` |
| `jq` (macOS/Linux) oppure PowerShell 7+ (Windows) | script degli hook in M3/M5 | `jq --version` / `pwsh --version` |
| **tokensave** | M4 | `tokensave --version` |

> Installazione della CLI di Claude Code: [code.claude.com/docs/en/setup](https://code.claude.com/docs/en/setup). L'estensione VS Code non aggiunge `claude` al `PATH`, serve l'installazione separata.
>
> Installazione di tokensave ([tokensave.dev](https://tokensave.dev/)): 
<br/>- `brew install aovestdipaperino/tap/tokensave` (macOS) 
<br/>- `scoop bucket add tokensave https://github.com/aovestdipaperino/scoop-aovestdipaperino && scoop install tokensave` (Windows) 
<br/>- `cargo install tokensave` (richiede Rust).
<br/>- In alternativa, qui sono presenti i binari precompilati per macOS, Windows e Linux: [tokensave.dev/releases](https://github.com/aovestdipaperino/tokensave/releases/).

## Setup

### Step 1 - Clona il repository

```bash
git clone https://github.com/BlexinSrl/sacmi-claudecode-workshop.git
cd sacmi-claudecode-workshop
```

> ⚠️ **Claude Code deve lavorare sempre dal root del repo.** Claude Code cerca `CLAUDE.md/AGENTS.md` e `.claude/` nella cartella da cui parte: se lo avvii da una sottocartella, skill, subagent e hook che crei non vengono caricati.
> - **Estensione VS Code**: apri il root con `code .` e tienilo come workspace per tutto il workshop. Apri i README dei moduli come **file** (Explorer oppure `Cmd/Ctrl+P`), **non** con `File => Open Folder` sulla cartella del modulo.
> - **CLI**: lancia `claude` sempre dal root del repo, non dalla cartella dello starter. Per i comandi di build e test usa un secondo terminale.

### Step 2 - Avvia Claude Code ed effettua il login

- **Estensione VS Code**: apri un file qualsiasi e clicca l'icona ✱ nella barra in alto a destra dell'editor.
- **CLI**: dal root del repo esegui `claude`.

Al primo avvio accedi con il tuo account Anthropic (nella CLI, se non parte da solo, digita `/login`) e, se richiesto, conferma che ti fidi della cartella.

**Risultato atteso**: Claude Code accetta un prompt. Prova con *"Riassumimi in 3 righe cosa contiene questo repository"*: la risposta cita il workshop e i moduli M1-M5 (Claude Code ha letto il `CLAUDE.md` del root).

### Step 3 - Prepara lo starter del tuo linguaggio

In ogni modulo lavori nella cartella `modules/<modulo>/starters/<linguaggio>/`. Ogni modulo ha la sua copia dello starter, quindi **all'inizio di ogni modulo** esegui la preparazione nella cartella di quel modulo. Per M1:

```bash
# .NET
cd modules/M1-istruzioni/starters/dotnet
dotnet restore
dotnet test Tasks.Tests        # => Passed: 2

# TypeScript
cd modules/M1-istruzioni/starters/typescript
npm install
npm test                       # => Tests 2 passed (2)

# Python
cd modules/M1-istruzioni/starters/python
python3 -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest                         # => 2 passed
```

Per gli altri moduli sostituisci `M1-istruzioni` con la cartella del modulo (es. `M2-capacita`). Gli starter da M2 in poi partono con 6 test.

> ⚠️ **.NET**: lancia sempre `dotnet test Tasks.Tests`. Un `dotnet test` senza argomenti prende il progetto della web app, non esegue nessun test ed esce comunque con successo.
>
> **Python**: quando Claude esegue i test lancia i comandi in una shell propria, dove il venv potrebbe non essere attivo. Se vedi `pytest: command not found`, chiedigli di usare `.venv/bin/pytest` (Windows: `.venv\Scripts\pytest`).

### Step 4 - Approva il server MCP Context7

Il repo contiene già `.mcp.json` al root, che registra il server MCP **Context7** (endpoint HTTP hosted, non serve installare nulla). All'apertura del workspace Claude Code può chiederti di approvarlo: accetta.

**Verifica**: digita `/mcp` in Claude Code. `context7` deve risultare connesso; se è disabilitato o in attesa di approvazione, selezionalo e abilitalo. Lo userai in M2.

### Step 5 - Registra tokensave (per M4)

Dal terminale, una sola volta:

```bash
tokensave install --agent claude
```

Il comando registra il server MCP di tokensave nella tua configurazione utente di Claude Code (`~/.claude.json`, non nel repo) e aggiunge delle regole che invitano Claude a usarlo prima di leggere i files. L'indicizzazione del progetto (`tokensave init`) la farai durante M4.

### Step 6 - Installa il plugin episodic-memory (consigliato, per M4)

In M4 userai l'**episodic memory**, che cerca nelle tue **conversazioni passate**. Perché in M4 ci sia uno storico da interrogare, installala **ora**, così le sessioni di M1-M3 vengono indicizzate man mano. Dal terminale:

```bash
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install episodic-memory@superpowers-marketplace
```

In alternativa puoi farlo dall'interfaccia di gestione dei plugin: `/plugins` nell'estensione VS Code (**Manage plugins**), `/plugin` nella CLI. Aggiungi il marketplace `obra/superpowers-marketplace`, poi installa `episodic-memory`.

**Verifica**: `claude plugin list` mostra `episodic-memory@superpowers-marketplace` abilitato. Apri una **nuova conversazione** per caricare il plugin.

## Iniziamo! 🚀

Apri [`modules/M1-istruzioni/README.md`](modules/M1-istruzioni/README.md) e buon workshop!

### Estensione VS Code o CLI

I comandi che iniziano con `/` (`/mcp`, `/hooks`, `/agents`, `/memory`...) e le @-mention si usano allo stesso modo in entrambe le interfacce. Cambiano solo queste operazioni:

| Operazione | Estensione VS Code | CLI |
|---|---|---|
| Avviare Claude Code | icona ✱ con il root del repo aperto | `claude` dal root del repo |
| Nuova conversazione | pulsante per una nuova conversazione nel pannello | `/clear`, oppure esci e rilancia `claude` |
| Tornare a un checkpoint (M4) | pulsante di rewind sul messaggio | `Esc Esc` oppure `/rewind` |
| Gestire i plugin (M5) | `/plugins` | `/plugin` |
| Vedere le modifiche ai file | diff nell'editor | diff nel terminale (o `git diff`) |

Quando un modulo dice "apri una **nuova conversazione**", serve a far caricare a Claude Code i file appena creati (skill, subagent, hook, memorie) e a partire con un contesto pulito.

### Convenzioni usate nei moduli

- I **prompt da incollare** in Claude Code sono introdotti da *"Chiedi:"* o *"Invia:"* e formattati come citazione.
- `<linguaggio>` va sostituito con `dotnet`, `typescript` o `python`.
- `@modules/...` nel prompt è una **@-mention**: digitando `@` Claude Code propone file e cartelle da allegare al contesto.
- Ogni modulo ha una cartella `solution/` con lo stato finale di riferimento. **Non modificarla**: se ti blocchi, copia da lì.
