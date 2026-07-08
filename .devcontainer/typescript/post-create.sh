#!/usr/bin/env bash
# Best-effort: NIENTE `set -e`. Un singolo comando che fallisce (una install a freddo, un
# download transitorio, ...) non deve abortire l'intero post-create e lasciare il container a
# meta'. Gli step gestiscono i propri errori con `|| true` / if.
set -uo pipefail

echo "==> Workshop post-create (TypeScript)"

for module in M1-istruzioni M2-capacita M3-governance M4-contesto-memoria M5-distribuzione; do
  for path in "modules/$module/starters/typescript" "modules/$module/solution/typescript"; do
    if [ -f "$path/package.json" ]; then
      echo "  - npm install $path"
      (cd "$path" && npm install --no-audit --no-fund) || true
    fi
  done
done

# Tooling M4 condiviso (tokensave + CLI Claude + promemoria episodic-memory + messaggio finale).
TOOLING="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tooling.sh"
# shellcheck source=../tooling.sh
source "$TOOLING" || echo "WARN: tooling condiviso non caricato ($TOOLING)"
