#!/bin/sh
set -eu

DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)

# Link dotfiles, preserving directory structure.
(
    cd "$DIR/dots"
    find . -type f | while IFS= read -r file; do
        dst="$HOME/${file#./}"
        mkdir -p "$(dirname "$dst")"

        if [ -e "$dst" ] || [ -L "$dst" ]; then
            printf 'Already exists: %s\n' "$dst"
            continue
        fi

        ln -s "$DIR/dots/${file#./}" "$dst"
    done
)

# Sensitive directory and file permissions.
chmod 700 "$HOME/.ssh" "$HOME/.gnupg"
chmod 600 "$HOME/.ssh/config" \
          "$HOME/.gnupg/gpg.conf" \
          "$HOME/.gnupg/gpg-agent.conf"
