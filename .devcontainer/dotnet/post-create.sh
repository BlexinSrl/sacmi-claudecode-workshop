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
# tokensave: code-intelligence MCP server. L'immagine universal NON ha Rust/cargo, quindi
# scarichiamo il binario PRECOMPILATO dalle release GitHub (niente compilazione da sorgente,
# lenta e fragile su 2-core). Vedi tokensave.dev per i 3 passi: 1) binario, 2) `tokensave
# install` registra il server MCP + prompt rules per Claude Code (config utente ~/.claude.json),
# 3) `tokensave init`. Qui facciamo 1) e 2); NIENTE init (hands-on M4). Nulla deve bloccare il
# post-create.
if ! command -v tokensave >/dev/null 2>&1; then
  case "$(uname -m)" in
    x86_64|amd64)  ts_target="x86_64-linux" ;;
    aarch64|arm64) ts_target="aarch64-linux" ;;
    *)             ts_target="" ;;
  esac
  if [ -n "$ts_target" ] && command -v curl >/dev/null 2>&1; then
    ts_tag="$(curl -fsSL https://api.github.com/repos/aovestdipaperino/tokensave/releases/latest \
                | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name" *: *"([^"]+)".*/\1/')"
    if [ -n "$ts_tag" ]; then
      echo "  - installing tokensave ($ts_tag, prebuilt $ts_target)"
      mkdir -p "$HOME/.local/bin"
      if curl -fsSL "https://github.com/aovestdipaperino/tokensave/releases/download/${ts_tag}/tokensave-${ts_tag}-${ts_target}.tar.gz" \
           | tar -xz -C "$HOME/.local/bin" tokensave; then
        chmod +x "$HOME/.local/bin/tokensave" || true
      else
        echo "  WARN: download tokensave fallito. Vedi modules/M4-contesto-memoria/README.md"
      fi
    else
      echo "  WARN: impossibile risolvere l'ultima release di tokensave. Vedi modules/M4-contesto-memoria/README.md"
    fi
  else
    echo "  WARN: tokensave non installato (arch non supportata o curl assente). Vedi modules/M4-contesto-memoria/README.md"
  fi
fi
# ~/.local/bin e' gia' sul PATH del codespace; garantiamo che lo sia anche in questa shell
export PATH="$HOME/.local/bin:$PATH"
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
