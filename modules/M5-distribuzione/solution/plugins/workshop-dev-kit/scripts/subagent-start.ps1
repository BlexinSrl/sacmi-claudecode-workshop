#!/usr/bin/env pwsh
# SubagentStart hook (Claude Code, PowerShell): injects the DB schema into the subagent context.
#
# Registered in the plugin's hooks/hooks.json with matcher "^workshop-dev-kit:dba$": runs only when the plugin's dba subagent starts.
# Output contract: stdout JSON with hookSpecificOutput.additionalContext.
# Exit 0 = allow; the text in additionalContext is added to the subagent context.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$schemaFile = Join-Path $scriptDir "../context/db-schema.sql"

if (-not (Test-Path $schemaFile)) {
    exit 0
}

$schemaBody = Get-Content -LiteralPath $schemaFile -Raw
$contextMsg = @"
Current application database schema (source of truth, injected by the SubagentStart hook):

``````sql
$schemaBody
``````

Use only table and column names that appear above. If the request cannot be answered with this schema, say so explicitly.
"@
$output = @{
    hookSpecificOutput = @{
        hookEventName     = "SubagentStart"
        additionalContext = $contextMsg
    }
}
$output | ConvertTo-Json -Depth 4 -Compress

exit 0
