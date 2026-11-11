#!/bin/sh
set -eu

DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)

# Directories
mkdir -p "$HOME/src" "$HOME/tmp" "$HOME/.config"

# Packages
sudo apt-get update
sudo apt-get install -y \
    bear \
    build-essential \
    clang \
    clangd \
    clang-format \
    cmake \
    curl \
    docker.io \
    docker-compose \
    emacs \
    git \
    libtool \
    libtool-bin \
    ripgrep \
    syncthing \
    tmux

# Configuration
sh "$DIR/dots.sh"
