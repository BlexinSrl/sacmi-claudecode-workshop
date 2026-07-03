#!/usr/bin/env pwsh
# SubagentStart hook (Claude Code, PowerShell): inietta lo schema del DB nel contesto del subagente.
#
# Registrato in .claude/settings.json con matcher "dba": gira solo quando parte il subagent dba.
# Output contract: stdout JSON con hookSpecificOutput.additionalContext.
# Exit 0 = allow; il testo in additionalContext viene aggiunto al contesto del subagente.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$schemaFile = Join-Path $scriptDir "../context/db-schema.sql"

if (-not (Test-Path $schemaFile)) {
    exit 0
}

$schemaBody = Get-Content -LiteralPath $schemaFile -Raw
$contextMsg = @"
Schema corrente del database applicativo (fonte di verità, iniettato dal SubagentStart hook):

``````sql
$schemaBody
``````

Usa esclusivamente nomi di tabella e colonne presenti qui sopra. Se la richiesta non è soddisfacibile con questo schema, dillo esplicitamente.
"@
$output = @{
    hookSpecificOutput = @{
        hookEventName     = "SubagentStart"
        additionalContext = $contextMsg
    }
}
$output | ConvertTo-Json -Depth 4 -Compress

exit 0
