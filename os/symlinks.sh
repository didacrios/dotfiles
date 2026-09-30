#!/bin/bash

# Link the versioned dotfiles into the home directory.
#
# The repository stays the single source of truth and $HOME only holds symlinks,
# so `git pull` is enough to update a shell config, a script or a desktop entry.
# Idempotent: re-running replaces each link with the same target.
#
# Deliberately NOT linked:
#   .gitconfig — $HOME/.gitconfig is a real per-machine file (user, email,
#                credentials). The tracked copy is a CHANGEME template, so
#                linking it would overwrite a working git identity.

set -euo pipefail
shopt -s nullglob

readonly dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0

link() {
  local -r source="$1"
  local -r target="$2"

  if [ ! -e "$source" ]; then
    echo "⚠️  Skipped, missing source: $source"
    failures=$((failures + 1))
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  ln -sfn "$source" "$target"
  echo "🔗 ${target} -> ${source}"
}

link "$dotfiles_dir/.zshrc" "$HOME/.zshrc"

# Every script in shell/bin becomes a command available on $PATH.
for script in "$dotfiles_dir"/shell/bin/*; do
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Every desktop entry in shell/desktop appears in the application launcher.
for entry in "$dotfiles_dir"/shell/desktop/*.desktop; do
  link "$entry" "$HOME/.local/share/applications/$(basename "$entry")"
done

# Refresh the launcher cache so newly linked entries are picked up immediately.
if command -v update-desktop-database > /dev/null; then
  update-desktop-database "$HOME/.local/share/applications" &> /dev/null || true
fi

if [ "$failures" -ne 0 ]; then
  echo "❌ ${failures} dotfile(s) could not be linked."
  exit 1
fi

echo "✅ Dotfiles linked"
