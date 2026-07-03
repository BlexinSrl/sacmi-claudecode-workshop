#!/usr/bin/env bash
set -euo pipefail

echo "==> Workshop post-create (Python)"

# La feature python installa gli eseguibili (uvicorn, pytest, ...) in una cartella
# che non è nel PATH dell'utente. La aggiungiamo dinamicamente (niente versione hardcoded)
# così i comandi sono lanciabili per nome e sparisce il warning di pip.
PY_SCRIPTS="$(python -c 'import sysconfig; print(sysconfig.get_path("scripts"))')"
if [ -n "$PY_SCRIPTS" ]; then
  for rc in "$HOME/.bashrc" "$HOME/.profile"; do
    if [ -f "$rc" ] && ! grep -qF "$PY_SCRIPTS" "$rc"; then
      echo "export PATH=\"$PY_SCRIPTS:\$PATH\"" >> "$rc"
    fi
  done
  export PATH="$PY_SCRIPTS:$PATH"
fi

for module in M1-istruzioni M2-capacita M3-governance M4-contesto-memoria M5-distribuzione; do
  for path in "modules/$module/starters/python" "modules/$module/solution/python"; do
    if [ -f "$path/requirements.txt" ]; then
      echo "  - pip install $path"
      (cd "$path" && python -m pip install -q --no-warn-script-location -r requirements.txt) || true
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
