#!/usr/bin/env bash
# Best-effort: NIENTE `set -e`. Un singolo comando che fallisce (una install a freddo, un
# download transitorio, ...) non deve abortire l'intero post-create e lasciare il container a
# meta'. Gli step gestiscono i propri errori con `|| true` / if.
set -uo pipefail

echo "==> Workshop post-create (Python)"

# La feature python installa gli eseguibili (uvicorn, pytest, ...) in una cartella che non e'
# nel PATH dell'utente. La aggiungiamo dinamicamente (niente versione hardcoded) cosi' i comandi
# sono lanciabili per nome e sparisce il warning di pip.
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

# Tooling M4 condiviso (tokensave + CLI Claude + promemoria episodic-memory + messaggio finale).
TOOLING="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tooling.sh"
# shellcheck source=../tooling.sh
source "$TOOLING" || echo "WARN: tooling condiviso non caricato ($TOOLING)"
