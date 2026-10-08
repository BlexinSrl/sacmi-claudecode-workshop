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

Segui questi passi in ordine, dopo aver verificato i [prerequisiti](#prerequisiti). **Scegli un solo linguaggio**: .NET, TypeScript oppure Python.

### 1. Clona il repository

Nel terminale:

```bash
git clone https://github.com/BlexinSrl/sacmi-claudecode-workshop.git
cd sacmi-claudecode-workshop
```

**Questa è la cartella principale del workshop (root).** Avvia sempre Claude Code da qui. In VS Code apri questa cartella con **File → Apri cartella** oppure `code .`; i README dei moduli vanno aperti come file, senza cambiare workspace.

### 2. Configura gli strumenti per M4

Nello stesso terminale, esegui una sola volta:

```bash
tokensave install --agent claude
```

L'indicizzazione con `tokensave init` si farà durante M4.

**Consigliato:** installa anche episodic-memory adesso, così raccoglie le conversazioni dei primi moduli:

```bash
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install episodic-memory@superpowers-marketplace
claude plugin list
```

Nell'elenco deve comparire `episodic-memory@superpowers-marketplace` abilitato.

### 3. Prepara lo starter: esegui solo il blocco del tuo linguaggio

Apri un **secondo terminale nella cartella principale del repository** e scegli uno dei blocchi qui sotto. Usa questo terminale per build e test.

**.NET**

```bash
cd modules/M1-istruzioni/starters/dotnet
dotnet restore
dotnet test Tasks.Tests
```

**TypeScript**

```bash
cd modules/M1-istruzioni/starters/typescript
npm install
npm test
```

**Python — macOS / Linux**

```bash
cd modules/M1-istruzioni/starters/python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest
```

**Python — Windows (PowerShell)**

```powershell
cd modules/M1-istruzioni/starters/python
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pytest
```

**Risultato atteso: 2 test superati.** Con .NET usa sempre `dotnet test Tasks.Tests`: senza `Tasks.Tests` il comando può terminare senza eseguire test.

Se Claude non trova `pytest`, chiedigli di usare `.venv/bin/pytest` su macOS/Linux oppure `.venv\Scripts\pytest` su Windows, dalla cartella dello starter.

### 4. Avvia Claude Code e accedi

- **VS Code:** con la cartella principale aperta, apri un file e clicca l'icona ✱ di Claude Code in alto a destra nell'editor.
- **CLI:** nel **primo terminale**, ancora nella cartella principale, esegui `claude`.

Accedi con il tuo account Anthropic (nella CLI usa `/login` se necessario). Se richiesto, conferma che ti fidi della cartella e approva il server MCP **Context7**, già configurato nel repository.

Se Claude Code era già aperto durante il passo 2, chiudilo e riaprilo per caricare gli strumenti appena installati.

### 5. Controlla di essere pronto

In Claude Code:

1. Digita `/mcp`: `context7` deve risultare **connesso**. Se è disabilitato o in attesa di approvazione, selezionalo e abilitalo.
2. Invia: *"Riassumimi in 3 righe cosa contiene questo repository"*. La risposta deve riconoscere il workshop e i moduli M1–M5.

**Se lo starter ha superato i 2 test e questi controlli sono riusciti, sei pronto.**

## Iniziamo! 🚀

Apri [`modules/M1-istruzioni/README.md`](modules/M1-istruzioni/README.md) e buon workshop!

### Estensione VS Code o CLI

I comandi che iniziano con `/` (`/mcp`, `/hooks`, `/memory`...) e le @-mention di file e cartelle si usano allo stesso modo in entrambe le interfacce. Cambiano solo queste operazioni:

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
