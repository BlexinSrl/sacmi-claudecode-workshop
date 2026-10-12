# Modulo M5 - Distribuzione · Plugins & Marketplace

> Obiettivo: trasformare le estensioni create nei moduli precedenti (skill, subagent, hook) in un'**unità distribuibile e installabile**, da condividere con il team o l'organizzazione.

## Teoria

### Plugin

Un plugin è un **bundle versionato** che raccoglie più estensioni in un'unica cartella con un manifest. Può contenere:

- una o più **skill** (`skills/`)
- uno o più **subagent** (`agents/`)
- una o più definizioni di **hook** (`hooks/hooks.json`)
- una o più configurazioni di **server MCP** (`.mcp.json`)

Il manifest `.claude-plugin/plugin.json` contiene i metadati (name, version, description...). I componenti **non vanno elencati** nel manifest: Claude Code li trova da solo nelle cartelle convenzionali.

Una volta installato, il plugin espone i suoi componenti come se fossero definiti nel repository, ma con un **prefisso** che evita conflitti di nome: la skill `endpoint-creator` del plugin `workshop-dev-kit` diventa `/workshop-dev-kit:endpoint-creator` e il subagent `dba` diventa `workshop-dev-kit:dba`.

### Marketplace

Un **marketplace** è un catalogo di plugin pubblicato come repository Git (pubblico o privato). Il file `.claude-plugin/marketplace.json` al suo root elenca i plugin e dice dove trovarli. È l'analogo di un package registry (npm, NuGet, PyPI), ma per estensioni di Claude Code invece che per librerie di codice.

Il flusso di installazione ha due fasi: **registri il marketplace** (una volta), poi **installi i singoli plugin** con `<plugin>@<marketplace>`.

## Hands-on

In questo modulo non lavori sulla Task API del workshop: crei un **nuovo repository** separato. Ti servono un account GitHub (o un altro host Git) e la CLI `claude`.

### Step 1 - Guarda un marketplace reale

Nel Setup hai già registrato il marketplace `superpowers-marketplace` e installato `episodic-memory`. Se non l'hai fatto, esegui ora lo [Step 6 del Setup](../../README.md#step-6---installa-il-plugin-episodic-memory-consigliato-per-m4).

In Claude Code apri la gestione dei plugin (`/plugins` nell'estensione VS Code, `/plugin` nella CLI): sfoglia i plugin disponibili nel marketplace `superpowers-marketplace` e quelli installati.

Da terminale ottieni le stesse informazioni:

```bash
claude plugin marketplace list
claude plugin list
```

### Step 2 - Ispeziona un plugin installato

Prima di costruire il tuo, guarda com'è fatto un plugin reale. I plugin installati vengono copiati in `~/.claude/plugins/cache/<marketplace>/<plugin>/<versione>/`:

```bash
ls ~/.claude/plugins/cache/superpowers-marketplace/episodic-memory/
ls -a ~/.claude/plugins/cache/superpowers-marketplace/episodic-memory/*/
```

Ritrovi le cartelle convenzionali:

- `.claude-plugin/plugin.json`: il manifest (name, version, description);
- `hooks/hooks.json`: associa un evento allo script da eseguire (qui `SessionStart` => sincronizzazione dell'indice delle conversazioni);
- `skills/`, `agents/`: i componenti veri e propri;
- `.mcp.json`: il server MCP che espone gli strumenti di ricerca.

### Step 3 - Crea il repo marketplace e assembla il plugin

Crea una cartella **fuori** dal repository del workshop, ad esempio `~/my-workshop-marketplace`. Al suo interno assembli il plugin `workshop-dev-kit` copiando le estensioni che hai creato nei moduli M1, M2 ed M3:

```
my-workshop-marketplace/
└── plugins/
    └── workshop-dev-kit/
        ├── .claude-plugin/
        │   └── plugin.json                  (manifest: solo metadati, vedi sotto)
        ├── hooks/
        │   └── hooks.json                   (registra l'hook SubagentStart, vedi sotto)
        ├── context/
        │   └── db-schema.sql                (da .claude/context/db-schema.sql)
        ├── skills/
        │   └── endpoint-creator/SKILL.md    (da .claude/skills/endpoint-creator/SKILL.md)
        ├── agents/
        │   └── dba.md                       (da .claude/agents/dba.md)
        └── scripts/
            ├── subagent-start.sh            (da .claude/hooks/subagent-start.sh)
            └── subagent-start.ps1           (da .claude/hooks/subagent-start.ps1)
```

> Scorciatoia: copia la cartella `modules/M5-distribuzione/solution/plugins` dentro `my-workshop-marketplace/`.

Il manifest `.claude-plugin/plugin.json` contiene **solo metadati**:

```json
{
  "name": "workshop-dev-kit",
  "version": "0.1.0",
  "description": "Workshop plugin: endpoint-creator skill + dba subagent + SubagentStart hook that injects the DB schema as context.",
  "author": { "name": "Workshop Participant", "email": "you@example.com" },
  "license": "MIT",
  "keywords": ["dba", "endpoint", "context"]
}
```

> ⚠️ **Nomi riservati**: un plugin non può chiamarsi `claude-...` o `anthropic-...` (sono prefissi riservati ad Anthropic). `claude plugin validate` lo segnala come errore.

L'hook si dichiara in `hooks/hooks.json`, con lo **stesso formato** della chiave `hooks` di `.claude/settings.json` usata in M3, ma con due differenze importanti:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "^workshop-dev-kit:dba$",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/scripts/subagent-start.sh\"", "timeout": 10 }
        ]
      }
    ]
  }
}
```

1. **Il matcher**: il subagent del plugin si chiama `workshop-dev-kit:dba`, non `dba`. Con `"matcher": "dba"` (come in M3) l'hook **non scatterebbe mai**. Il matcher `^workshop-dev-kit:dba$` è un'espressione regolare che corrisponde esattamente al nome con prefisso.
2. **Il percorso dello script**: si usa `${CLAUDE_PLUGIN_ROOT}`, che a runtime punta alla cartella del plugin installato. Non serve aggiungere nulla in `.claude/settings.json`: Claude Code registra l'hook all'installazione del plugin.

> Lo script legge lo schema da `context/db-schema.sql` del plugin (lo risolve come `../context/db-schema.sql` rispetto a `scripts/`). Se non impacchetti quel file l'hook gira ma non inietta nulla, e il subagent `dba` parte senza la sua fonte di verità.
>
> Su Windows il comando richiede Git Bash con `jq`. In alternativa usa lo script PowerShell: `"command": "pwsh -NoProfile -File \"${CLAUDE_PLUGIN_ROOT}/scripts/subagent-start.ps1\""`.

**Checkpoint**: valida il plugin dalla cartella `my-workshop-marketplace`:

```bash
claude plugin validate ./plugins/workshop-dev-kit
# => ✔ Validation passed
```

### Step 4 - Trasforma il repo in un marketplace

Aggiungi al root di `my-workshop-marketplace` l'indice `.claude-plugin/marketplace.json`:

```
my-workshop-marketplace/
└──.claude-plugin/
    └── marketplace.json                 (indice del marketplace)
```

```json
{
  "name": "my-workshop-marketplace",
  "owner": { "name": "Your Name", "email": "you@example.com" },
  "description": "Il mio marketplace del workshop",
  "plugins": [
    {
      "name": "workshop-dev-kit",
      "source": "./plugins/workshop-dev-kit",
      "description": "endpoint-creator skill + dba subagent + SubagentStart schema-injection hook.",
      "version": "0.1.0"
    }
  ]
}
```

- `source` è un percorso relativo al root del marketplace (la cartella che contiene `.claude-plugin/`) e deve iniziare con `./`.
- Il `name` del plugin nel marketplace deve coincidere con il `name` in `plugin.json`.

**Checkpoint**:

```bash
claude plugin validate .
# => ✔ Validation passed
```

### Step 5 - Pubblica il marketplace

Crea un nuovo repository vuoto su GitHub (es. `my-workshop-marketplace`), poi dalla cartella del marketplace:

```bash
git init -b main
git add .
git commit -m "Add workshop marketplace"
git remote add origin https://github.com/render93/my-workshop-marketplace.git
git push -u origin main
```

> Se il repository è privato, chi installa deve avere accesso in lettura con le proprie credenziali git.

### Step 6 - Installa e prova il plugin

Prova il plugin in un progetto **fuori** dal repository del workshop, così le estensioni che vedi arrivano sicuramente dal plugin e non da `.claude/` del workspace.

Registra il marketplace e installa il plugin:

```bash
claude plugin marketplace add <tuo-utente>/my-workshop-marketplace
claude plugin install workshop-dev-kit@my-workshop-marketplace
claude plugin list        # => workshop-dev-kit@my-workshop-marketplace abilitato
```

In alternativa, dalla gestione dei plugin (`/plugins` nell'estensione, `/plugin` nella CLI): aggiungi il marketplace `<tuo-utente>/my-workshop-marketplace` => installa `workshop-dev-kit`.

Avvia Claude Code in `~/plugin-test` (estensione: `code ~/plugin-test` e poi icona ✱; CLI: `claude` dentro `~/plugin-test`), apri una **nuova conversazione** e verifica:

1. digitando `/` compare la skill `workshop-dev-kit:endpoint-creator`;
2. digitando `@` compare il subagent `workshop-dev-kit:dba`;
3. il canary test di M3 funziona anche tramite il plugin:

> Usando il subagent workshop-dev-kit:dba, elencami tutte le colonne della tabella `tasks` esattamente come sono nello schema, una per riga.

**Risultato atteso**: la lista contiene `test_audit_seal`. Skill, subagent, schema e hook sono arrivati tutti dal plugin.

> Se modifichi il plugin e ripubblichi, aggiorna con `claude plugin marketplace update my-workshop-marketplace` e poi `/reload-plugins` nella sessione (oppure apri una nuova conversazione).

## Wrap

- **Plugin** = estensioni (skill, subagent, hook, server MCP) raccolte in un bundle versionato, con un manifest di soli metadati e componenti trovati per convenzione.
- **Marketplace** = repository Git con un `marketplace.json` che elenca i plugin: si registra una volta, poi si installano i plugin con `<plugin>@<marketplace>`.
- I componenti di un plugin hanno un **prefisso** (`workshop-dev-kit:dba`): ricordalo quando scrivi i matcher degli hook.

## Problemi?

- **`claude plugin validate` fallisce**: leggi il messaggio, di solito indica il campo esatto (JSON non valido, nome riservato, `source` sbagliato).
- **`Source path does not exist` in installazione**: il `source` in `marketplace.json` non è relativo al root del marketplace o non inizia con `./`.
- **Il subagent del plugin non vede lo schema**: controlla il matcher (`^workshop-dev-kit:dba$`) e che `context/db-schema.sql` sia nel plugin.
- **Riferimenti**: `modules/M5-distribuzione/solution/` è la fotografia del repo marketplace completo (`.claude-plugin/marketplace.json` + `plugins/workshop-dev-kit/`), da copiare nel tuo repo marketplace.

🎉 Hai completato tutti i moduli del workshop!
