#!/usr/bin/env bash
# SubagentStart hook (Claude Code): injects the DB schema into the subagent context.
#
# Registered in the plugin's hooks/hooks.json with matcher "^workshop-dev-kit:dba$": runs only when the plugin's dba subagent starts.
# Input contract: reads from stdin a JSON with the session fields (session_id, cwd, ...).
# Output contract: stdout JSON with hookSpecificOutput.additionalContext (event "Context only").
# Exit 0 = allow; the text in additionalContext is added to the subagent context.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/../context/db-schema.sql"

if [ ! -f "$SCHEMA_FILE" ]; then
  exit 0
fi

# The matcher in hooks/hooks.json ensures this hook runs only for the dba subagent,
# so here we always inject the schema without inspecting the agent type.
SCHEMA_BODY=$(cat "$SCHEMA_FILE")
CONTEXT_MSG=$(printf 'Current application database schema (source of truth, injected by the SubagentStart hook):\n\n```sql\n%s\n```\n\nUse only table and column names that appear above. If the request cannot be answered with this schema, say so explicitly.' "$SCHEMA_BODY")
jq -n --arg ctx "$CONTEXT_MSG" '{hookSpecificOutput: {hookEventName: "SubagentStart", additionalContext: $ctx}}'

exit 0
