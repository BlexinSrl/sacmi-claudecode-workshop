# Modulo M3 - Governance · Hooks

> Obiettivo: usare gli hook per **iniettare contesto** negli agenti, garantendo che lavorino sempre con il contesto necessario.

> Tutti i file di riferimento sono in `modules/M3-governance/solution/.claude/`.

## Teoria

### Cos'è un hook

Un hook è un **handler esterno all'LLM**, eseguito dall'host in corrispondenza di eventi specifici del ciclo di vita di una sessione agentica. Eventi supportati:

| Evento             | Quando viene chiamato                                           | Caso tipico                                                                                |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `SessionStart`     | All'avvio di una nuova sessione                                 | Iniettare contesto globale (variabili env, stato del repo, dashboard di salute)            |
| `UserPromptSubmit` | Ogni volta che l'utente invia un prompt                         | Filtrare/arricchire il prompt, redazionare segreti, aggiungere contesto situazionale       |
| `PreToolUse`       | Prima dell'esecuzione di un tool (Bash, Edit, Write, MCP call…) | Bloccare operazioni pericolose, richiedere approvazioni, modificare l'input del tool       |
| `PostToolUse`      | Dopo l'esecuzione di un tool                                    | Eseguire formatter, registrare i risultati, avviare azioni successive                      |
| `PreCompact`       | Prima di una compressione automatica del contesto               | Salvare contesto importante, esportare lo stato prima del troncamento                      |
| `SubagentStart`    | Quando viene avviato un subagent                                | **Iniettare contesto specifico del subagente** (schema DB, contratti API, runbook)         |
| `SubagentStop`     | Quando il subagent termina                                      | Aggregare risultati, pulire le risorse del subagent                                        |
| `Stop`             | A fine sessione                                                 | Generare report, liberare risorse, inviare notifiche                                       |

### Il contratto

Lo hook riceve un JSON su stdin con il payload dell'evento, può fare qualsiasi cosa (leggere file, interrogare un DB, chiamare servizi), e comunica con l'host in due modi:

- **Tramite exit code**: `0` consente l'evento; un exit diverso da `0` lo blocca. Per `PreToolUse` un `exit 2` blocca l'azione e mostra all'agente lo stderr come motivo del blocco.
- **Tramite stdout JSON**: alcuni eventi (es. `SessionStart`, `SubagentStart`, `PostToolUse`) accettano in stdout un JSON con un campo `hookSpecificOutput.additionalContext`: il contenuto viene **iniettato nella conversation dell'agente come contesto di sistema**.

È questa seconda modalità che useremo: l'hook non blocca, ma *parla* all'agente.

### Differenza chiave rispetto a CLAUDE.md, skill e prompt

| Strumento  | Cosa è                              | Determinismo                          |
| ---------- | ----------------------------------- | ------------------------------------- |
| CLAUDE.md  | Suggerimento testuale all'LLM       | LLM può ignorarlo                     |
| Skill      | Modulo di istruzioni caricabile     | LLM decide se attivarla                |
| Hook       | **Codice** eseguito dall'host       | Esegue **sempre**, non aggirabile     |

Per il context engineering, la conseguenza è netta: un CLAUDE.md può *invitare* l'agente a "consultare lo schema del DB", ma se lo schema non è in contesto, l'agente può allucinare nomi di tabella e colonne. Un hook **garantisce** che lo schema sia in contesto ogni volta che serve.

## Hands-on

### Setup

Per velocizzare, copia i seguenti file:
- `modules/M3-governance/solution/.claude/context/db-schema.sql` (lo schema del DB iniettato dall'hook con la canary column `test_audit_seal`) in `.claude/context/db-schema.sql`
- `modules/M3-governance/solution/.claude/agents/dba.md` (la definizione del subagente DBA, invocabile con `@agent-dba`) in `.claude/agents/dba.md`

In base al tuo sistema operativo, copia lo script giusto:
- `modules/M3-governance/solution/.claude/hooks/subagent-start.sh` (implementazione bash da associare all'hook `SubagentStart`) in `.claude/hooks/subagent-start.sh`
- `modules/M3-governance/solution/.claude/hooks/subagent-start.ps1`: (implementazione PowerShell da associare all'hook `SubagentStart`) in `.claude/hooks/subagent-start.ps1`

**Crea il seguenti file al root del workspace:**

`.claude/settings.json`** — registra l'hook (gli hook in Claude Code sono **attivi di default**, nessuna impostazione da spuntare):

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "dba",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/subagent-start.sh", "timeout": 10 }
        ]
      }
    ]
  }
}
```

Il `matcher: "dba"` fa sì che l'hook giri **solo** quando parte il subagent `dba` (il matcher di `SubagentStart` filtra sul nome dell'agente). Su Windows usa la versione PowerShell: `"command": "pwsh -File $CLAUDE_PROJECT_DIR/.claude/hooks/subagent-start.ps1"`.

**Verifica**:
- Esegui `/hooks` nel pannello Claude Code — deve comparire un `SubagentStart` registrato che punta al file giusto.
- Digitando `@` compare `dba` tra i subagenti.

### Lo schema iniettato

Apri `modules/M3-governance/solution/.claude/context/db-schema.sql`. Nota la colonna `test_audit_seal` nella tabella `tasks`: è una **canary column** — un nome inventato che non può esistere nel training data di nessun LLM. La useremo per dimostrare in modo inconfutabile che l'iniezione ha funzionato.

### Cosa fa lo hook

Apri `modules/M3-governance/solution/.claude/hooks/subagent-start.sh`. La logica è semplice perché il filtro sul subagent è fatto dal `matcher: "dba"` in `settings.json` (non serve leggere il tipo di agente nello script):

1. Legge `db-schema.sql`.
2. Lo emette su stdout come JSON `{"hookSpecificOutput": {"hookEventName": "SubagentStart", "additionalContext": "...lo schema..."}}`.

`SubagentStart` è un evento "context only": Claude aggiunge l'`additionalContext` come contesto di sistema **solo per il subagente appena avviato** — non inquina la sessione principale.

### Step 1 - Prova che l'iniezione funziona (canary test)

Nel pannello Claude Code chiedi:

> Elencami tutte le colonne della tabella `tasks` esattamente come sono nello schema attuale, una per riga, senza commenti usando il subagent dba

Risposta attesa: una lista di ~9 colonne **che include `test_audit_seal`**.

- Se compare `test_audit_seal` => l'iniezione via `SubagentStart` ha funzionato. Quel nome non esiste in nessun training data, può solo venire dal nostro `db-schema.sql`.
- Se non compare => lo hook non si è agganciato. Verifica con `/hooks` che l'hook sia registrato e che il `matcher` sia `dba`.

### Step 2 - Estendi lo schema

Apri `.claude/context/db-schema.sql` e aggiungi una colonna in fondo alla tabella `tasks`, prima della parentesi chiusa:

```sql
    parent_task_id  INTEGER REFERENCES tasks(id)
```

Salva. **Avvia una nuova conversazione** (l'hook rilegge il file a ogni `SubagentStart`, ma il subagente esistente ha già il contesto vecchio).

Ora chiedi:

> Scrivimi una query che restituisce tutti i task figli di un task con id = 42, ordinati per priorità decrescente usando il subagent dba

Il subagent `dba` userà `parent_task_id` nella `WHERE`: lo schema iniettato è cambiato e il subagente si è aggiornato.

## Wrap

- Un hook `SubagentStart` ti permette di **garantire** che ogni dispatch di un subagente parta con la ground truth nel contesto — schema DB, contratti API interni, runbook operativi.
- L'host (Claude Code) accetta in stdout `hookSpecificOutput.additionalContext`: questa è l'API documentata per la context injection, non un trucco.
- Lo stesso meccanismo, usato con un exit code di blocco invece che con `additionalContext`, ti permette di **bloccare** azioni (`PreToolUse`) — è la stessa famiglia di pattern. Il modulo si concentra sul caso iniettivo perché è più sottile e meno coperto in letteratura.

## Problemi?
Se ti blocchi: la cartella `solution` contiene già tutti i file pronti.

➡️ Prossimo modulo: [`../M4-contesto-memoria/README.md`](../M4-contesto-memoria/README.md) (Contesto & Memoria)
