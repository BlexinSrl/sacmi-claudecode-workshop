#!/usr/bin/env bash
set -euo pipefail

echo "==> Workshop post-create (TypeScript)"

for module in M1-istruzioni M2-capacita M3-governance M4-contesto-memoria M5-distribuzione; do
  for path in "modules/$module/starters/typescript" "modules/$module/solution/typescript"; do
    if [ -f "$path/package.json" ]; then
      echo "  - npm install $path"
      (cd "$path" && npm install --no-audit --no-fund) || true
    fi
  done
done

# --- M4 (Contesto & Memoria): tooling pre-disponibile ---
# tokensave: code-intelligence MCP server (binario Rust). Install idempotente; NIENTE init
# (l'init del progetto è hands-on del partecipante in M4). Non deve bloccare il post-create.
if ! command -v tokensave >/dev/null 2>&1; then
  if command -v cargo >/dev/null 2>&1; then
    echo "  - installing tokensave (cargo)"
    cargo install tokensave --no-default-features || true
  else
    echo "  WARN: cargo non disponibile, tokensave non installato. Vedi modules/M4-contesto-memoria/README.md"
  fi
fi

# episodic-memory: attivazione MANUALE (plugin Claude Code) - vedi README principale.
echo "  episodic-memory (modulo M4): attivalo PRESTO in Claude Code, cosi' M1-M3"
echo "  vengono indicizzati. Comandi (dettagli nel README principale):"
echo "    /plugin marketplace add obra/superpowers-marketplace"
echo "    /plugin install episodic-memory@superpowers-marketplace"

echo "==> Done. Open modules/M1-istruzioni/README.md to start."
