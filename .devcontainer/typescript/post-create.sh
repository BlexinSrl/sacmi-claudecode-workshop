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
# tokensave: code-intelligence MCP server. L'immagine universal (Focal) ha glibc 2.31, troppo
# vecchia per il binario precompilato delle release (richiede glibc >=2.34). Lo installiamo via
# Homebrew (feature `homebrew` nel devcontainer.json): brew su Linux si porta la propria glibc,
# quindi la bottle gira comunque. Vedi tokensave.dev per i 3 passi: 1) binario, 2) `tokensave
# install` registra il server MCP + prompt rules per Claude Code (config utente ~/.claude.json),
# 3) `tokensave init`. Qui facciamo 1) e 2); NIENTE init (hands-on M4). Nulla deve bloccare il
# post-create.
if ! command -v brew >/dev/null 2>&1 && [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
if ! command -v tokensave >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "  - installing tokensave (brew)"
    HOMEBREW_NO_AUTO_UPDATE=1 brew install aovestdipaperino/tap/tokensave \
      || echo "  WARN: brew install tokensave fallito. Vedi modules/M4-contesto-memoria/README.md"
  else
    echo "  WARN: brew non disponibile, tokensave non installato. Vedi modules/M4-contesto-memoria/README.md"
  fi
fi
if command -v tokensave >/dev/null 2>&1; then
  echo "  - registering tokensave MCP server (tokensave install)"
  tokensave install --agent claude --git-hook no || true
fi
# ~/.local/bin sul PATH per la CLI claude installata sotto (installer nativo)
export PATH="$HOME/.local/bin:$PATH"

# Claude Code CLI da terminale (oltre all'estensione VS Code): installer nativo ufficiale
# (raccomandato dai doc). Non-root, mette il binario in ~/.local/bin (gia' sul PATH del
# codespace), si auto-aggiorna in background. Non deve bloccare il post-create.
if ! command -v claude >/dev/null 2>&1; then
  echo "  - installing Claude Code CLI (native installer)"
  curl -fsSL https://claude.ai/install.sh | bash || echo "  WARN: install Claude Code CLI fallito. Vedi https://code.claude.com/docs/en/setup"
fi

# episodic-memory: attivazione MANUALE (plugin Claude Code) - vedi README principale.
echo "  episodic-memory (modulo M4): attivalo PRESTO in Claude Code, cosi' M1-M3"
echo "  vengono indicizzati. Comandi (dettagli nel README principale):"
echo "    /plugin marketplace add obra/superpowers-marketplace"
echo "    /plugin install episodic-memory@superpowers-marketplace"

echo "==> Done. Open modules/M1-istruzioni/README.md to start."
