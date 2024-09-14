#!/bin/bash

set -euo pipefail

[[ -d ~/.gnupg ]]          || (echo "Missing .gnupg"     && exit 1)
[[ -f ~/.ssh/id_ed25519 ]] || (echo "Missing .ssh"       && exit 1)
[[ -f ~/.gitconfig ]]      || (echo "Missing .gitconfig" && exit 1)

# Setup directories
mkdir -p ~/tmp
mkdir -p ~/src
mkdir -p ~/.config

# Hide unused directories
chflags hidden ~/Desktop
chflags hidden ~/Documents
chflags hidden ~/Downloads
chflags hidden ~/Music
chflags hidden ~/Movies
chflags hidden ~/Pictures
chflags hidden ~/Public

#
# MacOS settings
#

# Disable natural scrolling
defaults write -g com.apple.swipescrolldirection -bool false

# Enable clicking
defaults write com.apple.AppleMultitouchTrackpad Clicking -boolean true
defaults -currentHost write -globalDomain com.apple.mouse.tapBehavior -int 0

# Dock
defaults write com.apple.dock "orientation" -string "left"
defaults write com.apple.dock "autohide" -bool "true"
defaults write com.apple.dock "show-recents" -bool "false"
killall Dock

# Finder
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
killall Finder

#
# Packages
#

# Install homebrew
[[ -d /opt/homebrew ]] || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add homebrew to path
if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' /Users/adam/.zprofile; then
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/adam/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install basics
brew install --quiet fd
brew install --quiet gh   # required for copilot
brew install --quiet git
brew install --quiet gnupg
brew install --quiet htop
brew install --quiet jq
brew install --quiet ripgrep
brew install --quiet wget

brew install --quiet docker
brew install --quiet docker-compose
brew install --quiet colima && brew services start colima

brew install --quiet clang-format
brew install --quiet cmake
brew install --quiet cmake-language-server
brew install --quiet go
brew install --quiet golangci-lint
brew install --quiet gopls
brew install --quiet node
brew install --quiet python3

brew install --quiet glfw
brew install --quiet libvterm # required for vterm

# Install casks
brew install --quiet --cask emacs
brew install --quiet --cask firefox
brew install --quiet --cask tableplus
brew install --quiet --cask little-snitch
brew install --quiet --cask zoom
brew install --quiet --cask 1password
brew install --quiet --cask syncthing
brew install --quiet --cask obsidian

# Install doom emacs
if ! [[ -d ~/.config/emacs ]]; then
    git clone git@github.com:adamrt/doom.d.git ~/.config/doom # my config
    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    ~/.config/emacs/bin/doom install
fi

echo "Don't forget to set CapsLock to Ctrl"
