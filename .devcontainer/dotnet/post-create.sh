#!/usr/bin/env bash
set -euo pipefail

echo "==> Workshop post-create (.NET)"

for module in M1-istruzioni M2-capacita M3-governance M4-contesto-memoria M5-distribuzione; do
  for path in "modules/$module/starters/dotnet" "modules/$module/solution/dotnet"; do
    if compgen -G "$path"/*.csproj > /dev/null; then
      echo "  - dotnet restore $path"
      (cd "$path" && dotnet restore --nologo) || true
    fi
  done
done

# --- M4 (Contesto & Memoria): tooling pre-disponibile ---
# tokensave: code-intelligence MCP server (binario Rust). Vedi tokensave.dev per i 3 passi:
#   1) installa il binario  2) `tokensave install` registra il server MCP + prompt rules per
#   Claude Code (idempotente, scrive nel config utente ~/.claude.json)  3) `tokensave init`.
# Qui facciamo 1) e 2); NIENTE `tokensave init`: l'indicizzazione del progetto è hands-on del
# partecipante in M4. Nessuno di questi passi deve bloccare il post-create.
if ! command -v tokensave >/dev/null 2>&1; then
  if command -v cargo >/dev/null 2>&1; then
    echo "  - installing tokensave (cargo)"
    cargo install tokensave --no-default-features || true
  else
    echo "  WARN: cargo non disponibile, tokensave non installato. Vedi modules/M4-contesto-memoria/README.md"
  fi
fi
if command -v tokensave >/dev/null 2>&1; then
  echo "  - registering tokensave MCP server (tokensave install)"
  tokensave install --agent claude --git-hook no || true
fi

# episodic-memory: attivazione MANUALE (plugin Claude Code) - vedi README principale.
echo "  episodic-memory (modulo M4): attivalo PRESTO in Claude Code, cosi' M1-M3"
echo "  vengono indicizzati. Comandi (dettagli nel README principale):"
echo "    /plugin marketplace add obra/superpowers-marketplace"
echo "    /plugin install episodic-memory@superpowers-marketplace"

echo "==> Done. Open modules/M1-istruzioni/README.md to start."
