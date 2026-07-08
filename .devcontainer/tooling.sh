# Tooling M4 condiviso dai tre post-create (dotnet/typescript/python).
# NON eseguire direttamente: va *sourced* dal post-create dopo il restore delle dipendenze.
# Installa tokensave + CLI Claude Code, stampa il promemoria episodic-memory e il messaggio
# finale. Best-effort: non abortisce mai (i post-create girano senza `set -e`).

# tokensave: code-intelligence MCP server. Binario PRECOMPILATO dalle release GitHub (no cargo).
# Richiede glibc >=2.34 -> il devcontainer usa universal:3-linux (Noble, glibc 2.39), non la
# 2-linux (Focal, glibc 2.31, troppo vecchia). Poi `tokensave install` registra il server MCP +
# prompt rules in ~/.claude.json. NIENTE `tokensave init`: e' hands-on del partecipante in M4.
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
        chmod +x "$HOME/.local/bin/tokensave"
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
export PATH="$HOME/.local/bin:$PATH"   # dir dove atterrano sia tokensave sia claude
if command -v tokensave >/dev/null 2>&1; then
  echo "  - registering tokensave MCP server (tokensave install)"
  tokensave install --agent claude --git-hook no || true
fi

# Claude Code CLI da terminale (oltre all'estensione VS Code): installer nativo ufficiale
# (raccomandato dai doc) -> ~/.local/bin, non-root, auto-update in background.
if ! command -v claude >/dev/null 2>&1; then
  echo "  - installing Claude Code CLI (native installer)"
  curl -fsSL https://claude.ai/install.sh | bash || echo "  WARN: install Claude Code CLI fallito. Vedi https://code.claude.com/docs/en/setup"
fi

# episodic-memory: attivazione MANUALE dentro Claude Code (serve login) - vedi README.
echo "  episodic-memory (M4): attivalo PRESTO in Claude Code, cosi' M1-M3 vengono indicizzati:"
echo "    /plugin marketplace add obra/superpowers-marketplace"
echo "    /plugin install episodic-memory@superpowers-marketplace"

echo "==> Done. Open modules/M1-istruzioni/README.md to start."
