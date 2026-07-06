# Claude Code Workshop

> Workshop hands-on su CLAUDE.md, Skills, Subagents, MCP, Hooks, Checkpoints, Memorie, Tokensave, Episodic memory, Plugins & Marketplace

> Questo workshop si segue con **Claude Code** (estensione VS Code). Concetti, teoria, prompt ed esercizi sono **identici** per i tre linguaggi di starter (.NET 10, TypeScript, Python): cambia solo lo stack del modulo che scegli. Tutte le customizations che creerai (skill, subagent, hook, plugin) vivono in `.claude/` (e in `plugins/`) al **root del workspace**.

### Step 1 - Fork del repository

Click sul pulsante **"Fork"** in alto a destra in questa pagina, oppure usa direttamente questo link:

👉 **[Fork BlexinSrl/sacmi-claudecode-workshop](https://github.com/BlexinSrl/sacmi-claudecode-workshop)** 👈
Nella pagina che si apre:
- **Owner**: il tuo account GitHub (lascia il default)
- **Repository name**: lascia `sacmi-claudecode-workshop` (o cambia se preferisci)
- **"Copy the main branch only"**: ✅ lasciato spuntato
- Click **"Create fork"**

### Step 2 - Crea il Codespace

**Dal tuo fork** (`github.com/TUO-USERNAME/sacmi-claudecode-workshop`):
1. Click sul pulsante verde **"Code"**.
2. Tab **"Codespaces"** => click sui tre puntini => "New with options...".

Si apre la pagina **"Create codespace"** di GitHub.

### Step 3 - Configura il Codespace

Nella pagina di creazione lascia invariati:
- **Branch**: `main`
- **Region**: `Europe West`
- **Machine type**: `2-core`
- ⚠️ **Dev container configuration**: scegli una voce in base al linguaggio che preferisci usare

| Opzione nel dropdown | Scegli se vuoi… |
|---|---|
| `Workshop · .NET 10` | seguire con lo starter ASP.NET Core Minimal API |
| `Workshop · TypeScript (Node 20)` | seguire con lo starter Hono (TS) |
| `Workshop · Python 3.11` | seguire con lo starter FastAPI |

> 🚫 **NON scegliere `Default project configuration`**: è l'opzione fallback di GitHub che usa un'immagine generica senza la pre-installazione di Claude Code, MCP server e dipendenze del workshop. Ogni devcontainer dedicato installa solo l'SDK del suo linguaggio.

Click **"Create codespace"** in basso a destra.

Attendere qualche minuto per la creazione e l'inizializzazione del Codespace. Al termine nel tab `Terminale` dovresti vedere il messaggio `==> Done. Open modules/M1-istruzioni/README.md to start.`.

### Step 4 - Avvio MCP server (Context7)
Il server MCP Context7 potrebbe non partire automaticamente al primo avvio del Codespace.

Digita `/mcp` nel pannello Claude Code per gestire i server: seleziona `context7` e approvalo quando richiesto.

### Step 5 - Cambio lingua della UI
Per cambiare la lingua della UI di VS Code (menu, notifiche, ecc.):
1. Command Palette => `Configure Display Language`
2. Scegli la lingua preferita (es. `english`)

### Step 6 - Accedi all'estensione Claude Code nel Codespace
Apri il pannello Claude Code (icona ✱ nella barra in alto a destra dell'editor, oppure dalla Activity Bar a sinistra) e accedi con il tuo account Anthropic quando richiesto.

### Step 7 - (Consigliato) Attiva episodic-memory prima di iniziare

Nel modulo **M4 (Contesto & Memoria)** userai l'**episodic memory**, che cerca nelle tue **conversazioni passate**. Perché in M4 ci sia uno storico da interrogare, conviene attivarla **ora, prima di M1**, così le sessioni di M1-M3 vengono indicizzate man mano. Nel pannello Claude Code:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install episodic-memory@superpowers-marketplace
```

Il plugin registra da sé un hook `SessionStart` che mantiene aggiornato l'indice. (tokensave, l'altro strumento di M4, è già installato **e registrato** dal devcontainer via `tokensave install`; in M4 ti resta solo `tokensave init`.) Dettagli in [`modules/M4-contesto-memoria/README.md`](modules/M4-contesto-memoria/README.md).

## Setup locale

Se non puoi usare GitHub Codespaces, puoi seguire il workshop in locale.

### Step 1 - Prerequisiti software

| Tool | Note |
|---|---|
| Git | per clonare il repo |
| VS Code (≥ 1.110) | per agent mode e plugin support |
| Estensione **Claude Code** | richiede un account Anthropic attivo |
| Node.js 20+ | richiesto **solo se scegli lo starter TypeScript**. Context7 ora è un endpoint HTTP hosted, non più un processo locale |
| **Uno** tra .NET 10 SDK / Python 3.11+ | solo per il linguaggio di starter che scegli (TypeScript usa già Node) |
| `jq` (Unix) o PowerShell 7+ (Windows) | necessario per gli hook script in M3/M5 |

### Step 2 - Passi setup

```bash
# 1. Clone del repo
git clone https://github.com/<owner>/<repo>.git
cd <repo>

# 2. Apri il workspace in VS Code
code .

# 3. Verifica Claude Code attivo (icona ✱ nella barra in alto a destra in VS Code)

# 4. Restore dipendenze per il tuo linguaggio
#    Solo per il modulo che inizi, non per tutti:

# .NET
cd modules/M1-istruzioni/starters/dotnet && dotnet restore && cd -

# TypeScript
cd modules/M1-istruzioni/starters/typescript && npm install && cd -

# Python (con venv consigliato)
cd modules/M1-istruzioni/starters/python
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
cd -
```

### Step 3 - Verifica che lo starter giri

Per testare che lo starter funzioni prima di iniziare i moduli:

```bash
# .NET
cd modules/M1-istruzioni/starters/dotnet
dotnet test Tasks.Tests
dotnet run            # => server su http://localhost:5000

# TypeScript
cd modules/M1-istruzioni/starters/typescript
npm test              # => 2 test passano
npm run dev           # => server su http://localhost:3000

# Python
cd modules/M1-istruzioni/starters/python
source .venv/bin/activate
pytest                # => 2 test passano
uvicorn app.main:app  # => server su http://localhost:8000
```

### Step 4 - Configurazione MCP server (Context7) in locale

Il repo contiene già `.mcp.json` al root del workspace, configurato per usare l'endpoint HTTP hosted di Context7 (`https://mcp.context7.com/mcp`).

Claude Code lo rileva all'apertura del workspace e ti chiede l'approvazione del server: accetta quando richiesto. Per gestirlo, digita `/mcp` nel pannello Claude Code. Non serve Node.js: l'endpoint è HTTP hosted.

```json
{
  "mcpServers": {
    "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" }
  }
}
```

### Step 5 - (Consigliato) Strumenti del modulo M4 in locale

In locale gli strumenti di **M4 (Contesto & Memoria)** non vengono installati automaticamente (niente devcontainer), quindi predisponili a mano:

- **Episodic memory** (ricerca nelle conversazioni passate): attivala **prima di iniziare M1**, così le sessioni di M1-M3 vengono indicizzate. Nel pannello Claude Code:
  ```
  /plugin marketplace add obra/superpowers-marketplace
  /plugin install episodic-memory@superpowers-marketplace
  ```
- **tokensave** (MCP di code intelligence): tre passi (vedi [tokensave.dev](https://tokensave.dev/)). **1)** installa il binario e mettilo sul `PATH` — `cargo install tokensave` oppure, su macOS, `brew install aovestdipaperino/tap/tokensave`; **2)** registra il server MCP per Claude Code con `tokensave install` (una volta — scrive l'entry nel config utente `~/.claude.json`, **non** nel `.mcp.json` del repo, e aggiunge le prompt rules tokensave-first); **3)** l'indicizzazione del progetto (`tokensave init`) la fai durante M4.

Approfondimenti in [`modules/M4-contesto-memoria/README.md`](modules/M4-contesto-memoria/README.md).

## Iniziamo! 🚀

> ⚠️ **Importante - non cambiare il workspace root**
>
> Il workspace VS Code deve **rimanere il root del repo** per tutto il workshop. Apri i README dei moduli come **file** (Explorer sidebar oppure `Cmd/Ctrl+P` => digita il path), **NON** con `File => Open Folder` sulla cartella del modulo.
>
> Perché: tutte le customizations Claude Code che creerai vivono in `.claude/` (skill, subagent, hook, `settings.json`) e in `plugins/` al **root del workspace**, con `CLAUDE.md` al root come contratto del repo. Se cambi workspace finiscono nel posto sbagliato e Claude Code non le carica.
>
> Suggerimento UX: con il README aperto, premi `Cmd+Shift+V` (macOS) o `Ctrl+Shift+V` (Win/Linux) per il preview Markdown formattato.

Apri [`modules/M1-istruzioni/README.md`](modules/M1-istruzioni/README.md) per iniziare dal modulo 1 e buona workshop! 🚀
