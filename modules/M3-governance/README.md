# Modulo M3 - Governance · Hooks

> Obiettivo: usare gli hook per **iniettare contesto** in un subagent, garantendo che lavori sempre con le informazioni necessarie invece di "sperare" che le vada a cercare.

## Teoria

### Cos'è un hook

Un hook è un **comando esterno all'LLM**, eseguito da Claude Code in corrispondenza di eventi specifici del ciclo di vita di una sessione. Gli eventi principali:

| Evento | Quando viene chiamato | Caso tipico |
| --- | --- | --- |
| `SessionStart` | All'avvio o alla ripresa di una sessione | Iniettare contesto globale (stato del repo, variabili d'ambiente) |
| `UserPromptSubmit` | Ogni volta che invii un prompt | Filtrare o arricchire il prompt, bloccare segreti |
| `PreToolUse` | Prima dell'esecuzione di un tool (Bash, Edit, Write, tool MCP...) | Bloccare operazioni pericolose |
| `PostToolUse` | Dopo l'esecuzione di un tool | Lanciare un formatter, registrare i risultati |
| `SubagentStart` | Quando parte un subagent | **Iniettare contesto specifico del subagent** (schema DB, contratti API, runbook) |
| `SubagentStop` | Quando un subagent termina | Verificare o aggregare il risultato |
| `Stop` | Quando Claude finisce di rispondere (fine turno) | Controlli finali, notifiche |
| `SessionEnd` | Alla chiusura della sessione | Pulizia, report |

L'elenco completo è nella [documentazione degli hook](https://code.claude.com/docs/en/hooks).

### Il contratto

L'hook riceve su stdin un JSON con i dati dell'evento, può fare qualsiasi cosa (leggere file, interrogare un servizio) e comunica con Claude Code in due modi:

- **Exit code**: `0` = tutto ok. `2` = errore bloccante: per gli eventi che lo prevedono (es. `PreToolUse`) l'azione viene bloccata e lo stderr viene mostrato a Claude come motivo. Altri codici sono errori non bloccanti.
- **JSON su stdout**: alcuni eventi (es. `SessionStart`, `SubagentStart`, `PostToolUse`) accettano un campo `hookSpecificOutput.additionalContext`, il cui testo viene **aggiunto al contesto dell'agente**.

In questo modulo usiamo la seconda modalità: l'hook non blocca, ma *parla* all'agente.

### Differenza rispetto a CLAUDE.md e skill

| Strumento | Cos'è | Determinismo |
| --- | --- | --- |
| CLAUDE.md | Istruzioni testuali per l'LLM | L'LLM può non seguirle |
| Skill | Modulo di istruzioni caricabile | L'LLM decide se caricarla |
| Hook | **Codice** eseguito da Claude Code | Gira **sempre** quando scatta l'evento |

Per il context engineering la conseguenza è netta: un `CLAUDE.md` può *invitare* l'agente a "consultare lo schema del DB", ma se lo schema non è nel contesto l'agente può inventare nomi di tabelle e colonne. Un hook **garantisce** che lo schema sia nel contesto ogni volta che serve.

## Hands-on

In questo modulo non modifichi il codice della Task API: lavori solo su file in `.claude/` al root del repo. Tutti i file di riferimento sono in `modules/M3-governance/solution/.claude/`.

**Prerequisito**: `jq --version` (macOS/Linux) oppure `pwsh --version` (Windows) deve rispondere: lo script dell'hook ne ha bisogno.

### Step 1 - Copia schema, subagent e script dell'hook

Dal **root del repo**, copia i file pronti:

```bash
# macOS / Linux
mkdir -p .claude/context .claude/agents .claude/hooks
cp modules/M3-governance/solution/.claude/context/db-schema.sql .claude/context/
cp modules/M3-governance/solution/.claude/agents/dba.md         .claude/agents/
cp modules/M3-governance/solution/.claude/hooks/subagent-start.sh .claude/hooks/
```

```powershell
# Windows (PowerShell)
New-Item -ItemType Directory -Force .claude/context, .claude/agents, .claude/hooks | Out-Null
Copy-Item modules/M3-governance/solution/.claude/context/db-schema.sql .claude/context/
Copy-Item modules/M3-governance/solution/.claude/agents/dba.md         .claude/agents/
Copy-Item modules/M3-governance/solution/.claude/hooks/subagent-start.ps1 .claude/hooks/
```

Cosa hai copiato:
- `.claude/context/db-schema.sql`: lo schema del database che l'hook inietterà.
- `.claude/agents/dba.md`: il subagent `dba`, esperto di SQL. Aprilo: dice al subagent che lo schema gli arriva già nel contesto e che non deve inventare colonne. Nota `tools: []`: il subagent non ha tool per leggere file, quindi lo schema può arrivargli **solo** dall'hook.
- `.claude/hooks/subagent-start.sh` (o `.ps1`): lo script dell'hook.

**Checkpoint**: nel root del repo esistono `.claude/context/`, `.claude/agents/` (con `code-reviewer.md` di M2 e `dba.md`) e `.claude/hooks/`.

### Step 2 - Guarda lo schema e lo script

Apri `.claude/context/db-schema.sql`. Nella tabella `tasks` c'è la colonna `test_audit_seal`: è una **canary column**, un nome inventato che nessun LLM può conoscere. La useremo per dimostrare che l'iniezione funziona: se il subagent la nomina, può averla vista solo tramite l'hook.

Apri `.claude/hooks/subagent-start.sh`. La logica è semplice:

1. legge `../context/db-schema.sql` (relativo alla cartella dello script);
2. stampa su stdout il JSON `{"hookSpecificOutput": {"hookEventName": "SubagentStart", "additionalContext": "...lo schema..."}}`.

Non serve controllare quale subagent sta partendo: il filtro lo fa il `matcher` che configuri nel prossimo step. `SubagentStart` aggiunge il contesto **solo al subagent appena avviato**: la sessione principale non viene appesantita.

Puoi provare lo script da solo, dal root del repo:

```bash
echo '{}' | bash .claude/hooks/subagent-start.sh | jq -r .hookSpecificOutput.hookEventName
# => SubagentStart
```

### Step 3 - Registra l'hook in `.claude/settings.json`

Crea il file `.claude/settings.json` al root del repo (se esiste già, aggiungi solo la chiave `hooks`):

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "dba",
        "hooks": [
          { "type": "command", "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/subagent-start.sh\"", "timeout": 10 }
        ]
      }
    ]
  }
}
```

- `matcher: "dba"`: per `SubagentStart` il matcher si confronta con il `name` del subagent, quindi l'hook gira **solo** quando parte `dba`.
- `${CLAUDE_PROJECT_DIR}`: Claude Code la imposta al root del progetto. Le virgolette proteggono i percorsi che contengono spazi.

Su **Windows** usa lo script PowerShell:

```json
{ "type": "command", "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/subagent-start.ps1\"", "timeout": 10 }
```

**Checkpoint**: apri una **nuova conversazione**, poi:
- digita `/hooks` (nell'estensione VS Code anche dal menu `/` => **Hooks**): deve comparire un hook `SubagentStart` con matcher `dba`;
- digita `@`: tra gli agenti deve comparire `dba`.

### Step 4 - Prova che l'iniezione funziona (canary test)

Chiedi:

> Usando il subagent dba, elencami tutte le colonne della tabella `tasks` esattamente come sono nello schema attuale, una per riga, senza commenti.

In alternativa invoca direttamente il subagent con `@agent-dba` seguito dalla domanda.

**Risultato atteso**: una lista di 9 colonne **che include `test_audit_seal`**.

- Compare `test_audit_seal` => l'iniezione via `SubagentStart` ha funzionato: quel nome può venire solo dal tuo `db-schema.sql`.
- Non compare, oppure il subagent dice di non avere uno schema => l'hook non si è agganciato. Vedi **Problemi?** in fondo.

### Step 5 - Modifica lo schema e osserva l'aggiornamento

Apri `.claude/context/db-schema.sql` e aggiungi una colonna in fondo alla tabella `tasks`. Attenzione alla virgola: la riga `test_audit_seal TEXT` deve diventare `test_audit_seal TEXT,`, poi aggiungi:

```sql
    parent_task_id  INTEGER REFERENCES tasks(id)
```

Salva e apri una **nuova conversazione**. L'hook rilegge il file a ogni avvio del subagent, ma la conversazione precedente contiene già la vecchia lista di colonne e l'agente principale potrebbe riusarla.

Chiedi:

> Usando il subagent dba, scrivimi una query che restituisce tutti i task figli del task con id = 42, ordinati per priorità decrescente.

**Risultato atteso**: la query usa `parent_task_id` nella `WHERE`. Lo schema iniettato è cambiato senza toccare né il subagent né l'hook.

## Wrap

- Un hook `SubagentStart` **garantisce** che ogni avvio di un subagent parta con la "fonte di verità" nel contesto: schema DB, contratti API interni, runbook operativi.
- Il canale è `hookSpecificOutput.additionalContext` su stdout: è l'API documentata di Claude Code per iniettare contesto.
- Lo stesso meccanismo, con `exit 2` invece di `additionalContext`, permette di **bloccare** azioni (`PreToolUse`): è la stessa famiglia di pattern.

## Problemi?

- **`/hooks` non mostra l'hook**: controlla che il file sia `.claude/settings.json` al **root** del repo, che il JSON sia valido e apri una nuova conversazione.
- **L'hook c'è ma `test_audit_seal` non compare**:
  - prova lo script a mano (comando dello Step 2): se fallisce, manca `jq` o il percorso dello schema è sbagliato;
  - verifica che il `name` nel frontmatter di `.claude/agents/dba.md` sia esattamente `dba` (deve coincidere con il `matcher`).
- **Ti blocchi**: copia `modules/M3-governance/solution/.claude/` (subagent, contesto, hook e `settings.json`) in `.claude/` al root del repo.

➡️ Prossimo modulo: [`../M4-contesto-memoria/README.md`](../M4-contesto-memoria/README.md)
