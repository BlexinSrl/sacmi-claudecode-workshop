#!/usr/bin/env bash
# SubagentStart hook (Claude Code): inietta lo schema del DB nel contesto del subagente.
#
# Registrato in .claude/settings.json con matcher "dba": gira solo quando parte il subagent dba.
# Input contract: legge da stdin un JSON con i campi della sessione (session_id, cwd, ...).
# Output contract: stdout JSON con hookSpecificOutput.additionalContext (evento "Context only").
# Exit 0 = allow; il testo in additionalContext viene aggiunto al contesto del subagente.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/../context/db-schema.sql"

if [ ! -f "$SCHEMA_FILE" ]; then
  exit 0
fi

# Il matcher "dba" in settings.json garantisce che questo hook giri solo per il subagent dba,
# quindi qui iniettiamo sempre lo schema senza dover ispezionare il tipo di agente.
SCHEMA_BODY=$(cat "$SCHEMA_FILE")
CONTEXT_MSG=$(printf 'Schema corrente del database applicativo (fonte di verità, iniettato dal SubagentStart hook):\n\n```sql\n%s\n```\n\nUsa esclusivamente nomi di tabella e colonne presenti qui sopra. Se la richiesta non è soddisfacibile con questo schema, dillo esplicitamente.' "$SCHEMA_BODY")
jq -n --arg ctx "$CONTEXT_MSG" '{hookSpecificOutput: {hookEventName: "SubagentStart", additionalContext: $ctx}}'

exit 0
