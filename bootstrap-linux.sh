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
    dmenu \
    docker.io \
    docker-compose \
    git \
    i3-wm \
    i3lock \
    i3status \
    libtool \
    libtool-bin \
    ripgrep \
    syncthing \
    tmux \
    x11-xserver-utils \
    xss-lock
    # emacs \ # built native

# Configuration
sh "$DIR/dots.sh"
