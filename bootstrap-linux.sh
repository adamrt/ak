#!/bin/sh
set -eu

DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)

# Directories
rm -rf "$HOME/Pictures" "$HOME/Movies" "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Public" "$HOME/Templates" "$HOME/Videos"
mkdir -p "$HOME/src" "$HOME/opt" "$HOME/tmp" "$HOME/.config"

# Packages
sudo apt-get update
sudo apt-get install -y \
    bear \
    build-essential \
    clang \
    clangd \
    clang-format \
    fonts-jetbrains-mono \
    git \
    ripgrep \
    syncthing

# Configuration
sh "$DIR/dots.sh"
sh "$DIR/bin/install-emacs.sh"
sh "$DIR/bin/install-go.sh"
