# Modulo M5 - Distribuzione · Plugins & Marketplace

> Obiettivo: trasformare le estensioni (skill, subagent, hook, configurazioni di MCP server) in **unità distribuibili e installabili** condivisibili col team o l'organizzazione.

> Concetti chiave: plugin = bundle versionato, marketplace = registry Git. In Claude Code il manifest è `.claude-plugin/plugin.json` (i componenti `skills/`, `agents/`, `hooks/hooks.json` sono **auto-scoperti** dalle cartelle convenzionali), il marketplace è `.claude-plugin/marketplace.json`, e l'installazione usa i comandi `/plugin marketplace add` e `/plugin install`. Riferimenti in `modules/M5-distribuzione/solution/.claude-plugin/marketplace.json` e `modules/M5-distribuzione/solution/plugins/claude-dev-kit/`.

## Teoria

### Plugin

Un plugin è un **bundle versionato** che raccoglie più estensioni in un singolo artefatto con un manifest dichiarativo. Un plugin può contenere:

- una o più **skill**
- uno o più **custom agent (subagent)**
- una o più definizioni di **hook**
- una o più configurazioni di **MCP server**

Il file manifest `.claude-plugin/plugin.json` contiene i metadati del bundle (name, version, description). I componenti `skills/`, `agents/` e `hooks/hooks.json` non vanno dichiarati: vengono **auto-scoperti** dalle cartelle convenzionali del plugin. Un plugin installato espone tutti i suoi componenti all'agente come se fossero stati definiti localmente nel repository.

### Marketplace

Un **marketplace** è un registry di plugin pubblicato come repository Git accessibile (pubblico o privato). Contiene un insieme di plugin e funge da source per l'installazione. Concettualmente è analogo a un package registry (npm, NuGet, PyPI), ma per artefatti agentici invece che per librerie di codice.

## Hands-on

### Step 1 - Installa un marketplace + plugin reale

Per provare l'installazione di un plugin **reale** usa il marketplace community ufficiale. Il flusso è in due fasi: prima registri il source (il marketplace), poi installi il singolo plugin.

Nota: se lo hai già fatto prima, puoi saltare questo step e passare direttamente allo Step 2.

```
/plugin marketplace add obra/superpowers-marketplace
```

Poi installa un plugin dal marketplace appena aggiunto, in uno dei due modi:

- **da UI**: `/plugin` apre il gestore → **Marketplaces** → sfoglia i plugin → **Install**;
- **da riga di comando**: `/plugin install episodic-memory@superpowers-marketplace`.

### Step 2 - Ispeziona un plugin reale

Prima di costruire il tuo, guarda com'è fatto un plugin reale: apri `~/.claude/plugins/marketplaces/` ed entra nella cartella del marketplace che hai aggiunto (es. `superpowers-marketplace`), poi naviga fino al plugin che hai installato. Ritrovi le stesse cartelle convenzionali:

- `.claude-plugin/plugin.json` — il manifest: name, version, description.
- `hooks/hooks.json` — mappa un evento (es. `PreToolUse`) allo script da eseguire.
- `skills/`, `agents/`, `scripts/` — i componenti veri e propri, **auto-scoperti** dalle cartelle convenzionali (non serve elencarli nel manifest).

### Step 3 - Crea il tuo repo-marketplace e assembla il plugin

Crea un **nuovo repository**, separato dal workspace del workshop. Al suo interno assembli il **plugin** `claude-dev-kit`: copia le varie estensioni che hai creato nel workspace. Il manifest del marketplace, che rende il plugin installabile, lo aggiungerai nello Step 4.

> Per comodità puoi copiare la cartella `modules/M5-distribuzione/solution/plugins`.

```
plugins/
└── claude-dev-kit/
    ├── .claude-plugin/
    │   └── plugin.json                  (manifest: solo metadati, vedi sotto)
    ├── hooks/
    │   └── hooks.json                   (registra l'hook SubagentStart => script, matcher "dba")
    ├── context/
    │   └── db-schema.sql                (copiato dal workspace: .claude/context/db-schema.sql)
    ├── skills/
    │   └── endpoint-creator/SKILL.md    (copiata dal workspace: .claude/skills/endpoint-creator/SKILL.md)
    ├── agents/
    │   └── dba.md                       (copiato dal workspace: .claude/agents/dba.md)
    └── scripts/
        ├── subagent-start.sh            (copiato dal workspace: .claude/hooks/subagent-start.sh)
        └── subagent-start.ps1           (copiato dal workspace: .claude/hooks/subagent-start.ps1)
```

Il manifest `.claude-plugin/plugin.json` contiene **solo metadati**: `skills/`, `agents/` e `hooks/hooks.json` vengono auto-scoperti dalle cartelle convenzionali.

```json
{
  "name": "claude-dev-kit",
  "version": "0.1.0",
  "description": "Workshop plugin: endpoint-creator skill + dba subagent + SubagentStart hook that injects the DB schema as context.",
  "author": { "name": "Workshop Participant", "email": "you@example.com" },
  "license": "MIT",
  "keywords": ["dba", "endpoint", "context"]
}
```

L'hook si dichiara in `hooks/hooks.json`, con lo **stesso formato** della chiave `hooks` di `settings.json` già usata nel workspace (M3): l'evento `SubagentStart` con `matcher: "dba"`, così gira solo all'avvio del subagent `dba`. L'unica differenza rispetto al workspace: lo script si referenzia con `${CLAUDE_PLUGIN_ROOT}` — es. `"command": "${CLAUDE_PLUGIN_ROOT}/scripts/subagent-start.sh"` — variabile che a runtime punta alla cartella del plugin installato. All'installazione Claude Code legge quel file e registra l'hook col proprio meccanismo nativo: non serve aggiungere nulla a mano in `.claude/settings.json` come faresti nel workspace.

> Lo script `subagent-start` legge lo schema da `context/db-schema.sql` (nella cartella del plugin, risolto dallo script come `../context/db-schema.sql` rispetto a `scripts/`): se quel file non viene impacchettato l'hook gira ma non inietta alcuno schema, e il subagent `dba` parte senza la sua fonte di verità. Per questo `db-schema.sql` fa parte del bundle.

### Step 4 - Aggiungi il marketplace, pubblica e installa

Ora rendi il repo un **marketplace** installabile: aggiungi al suo root l'indice `.claude-plugin/marketplace.json`, che elenca i plugin del repo. L'albero finale è quindi:

```
<nuovo-repo-marketplace>/
├── .claude-plugin/
│   └── marketplace.json                 (indice del marketplace)
└── plugins/
    └── claude-dev-kit/                  (il bundle assemblato nello Step 3)
```

```json
{
  "name": "my-workshop-marketplace",
  "owner": { "name": "Your Name", "email": "you@example.com" },
  "metadata": { "description": "Il mio marketplace del workshop", "version": "0.1.0", "pluginRoot": "./plugins" },
  "plugins": [
    {
      "name": "claude-dev-kit",
      "source": "./plugins/claude-dev-kit",
      "description": "endpoint-creator skill + dba subagent + SubagentStart schema-injection hook.",
      "version": "0.1.0"
    }
  ]
}
```

Poi pubblica:

1. `git init && git add . && git commit -m "workshop marketplace"`, poi `git push` su un nuovo repository GitHub.

E installa il plugin dal marketplace appena pubblicato:

1. Apri un nuovo terminale in un workspace pulito (per evitare conflitti)
2. `/plugin marketplace add <url-del-tuo-repo>`
3. `/plugin`, ricerca il plugin `claude-dev-kit` ed installalo (o `/plugin install claude-dev-kit@<nome-marketplace>` da riga di comando)
4. `/reload-plugins` per caricare i plugin appena installati
5. `/plugin list` per verificare che il plugin sia installato
6. Le estensioni del plugin sono ora disponibili

Reference: `modules/M5-distribuzione/solution/.claude-plugin/marketplace.json`.

## Wrap

- Plugin = insieme di estensioni per agenti AI (skill, agent, hook, MCP server) raccolti in un bundle versionato con manifest dichiarativo.
- Marketplace = registry da cui i plugin si installano (pubblico, privato o enterprise-managed).

## Problemi?

Se ti blocchi: `solution/plugins/claude-dev-kit/` contiene il bundle plugin completo e `solution/.claude-plugin/marketplace.json` l'indice del marketplace, da copiare al root del repo.

🎉 Hai completato tutti i moduli del workshop! Torna al [README principale](../../README.md).
