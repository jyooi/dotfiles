#!/usr/bin/env bash
# Install dotfiles by symlinking config into $HOME.
# Works on macOS and Arch Linux (Omarchy).
# Idempotent and non-destructive: real files are backed up before being replaced.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Darwin) OS="macOS" ;;
  Linux)  OS="Linux" ;;
  *)      OS="$(uname -s)" ;;
esac

TS="$(date +%Y%m%d-%H%M%S)"
linked=0
backed=0

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      printf '  ok      %s (already linked)\n' "$dest"
      return
    fi
    rm "$dest"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.bak.$TS"
    printf '  backup  %s -> %s.bak.%s\n' "$dest" "$dest" "$TS"
    backed=$((backed + 1))
  fi
  ln -s "$src" "$dest"
  printf '  link    %s -> %s\n' "$dest" "$src"
  linked=$((linked + 1))
}

echo "Installing dotfiles from $REPO on $OS"
link "$REPO/AGENTS.md"        "$HOME/AGENTS.md"
link "$REPO/OPINIONS.md"      "$HOME/OPINIONS.md"
link "$REPO/STACK.md"         "$HOME/STACK.md"
link "$REPO/MODEL_ROUTING.md" "$HOME/MODEL_ROUTING.md"
link "$REPO/AGENTS.md"        "$HOME/.claude/CLAUDE.md"

echo "Done. $linked linked, $backed backed up."
