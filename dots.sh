#!/bin/sh
# Symlink dotfiles from ~/src/ak/dots into $HOME.
set -eu

D="$HOME/src/ak/dots"

# Which machine is this?
#   Linux                    -> linux
#   Mac named FDK03H02RJ     -> mac-work
#   any other Mac            -> mac
case "$(uname -s)" in
Linux) machine=linux ;;
Darwin)
    if [ "$(scutil --get LocalHostName)" = FDK03H02RJ ]; then
        machine=mac-work
    else
        machine=mac
    fi
    ;;
*)
    echo "unknown OS: $(uname -s)" >&2
    exit 1
    ;;
esac
echo "machine: $machine"

# link SRC [DST]: symlink $D/SRC to ~/DST (DST defaults to SRC).
link() {
    src="$D/$1"
    dst="$HOME/${2:-$1}"
    mkdir -p "$(dirname "$dst")"
    if [ "$(readlink "$dst" 2>/dev/null)" = "$src" ]; then
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "exists, skipping: $dst" >&2
        return
    fi
    ln -s "$src" "$dst"
    echo "linked: $dst"
}

# All machines. Git identity is chosen per repo in .gitconfig.
link .emacs.el
link .gitconfig
link .gitconfig-work
link .gitignore
link .gnupg/gpg.conf
link .gnupg/gpg-agent.conf

case "$machine" in
linux)
    link .bashrc
    link .profile
    link .config/i3/config
    link .config/i3status/config
    link .config/environment.d/10-path.conf
    link .config/gtk-3.0/settings.ini
    link .local/share/applications/emacs-local.desktop
    ;;
mac)
    link .zprofile
    link .zshrc
    ;;
mac-work)
    link .zprofile
    link .zshrc
    ;;
esac

chmod 700 "$HOME/.gnupg"
chmod 600 "$HOME/.gnupg/gpg.conf" "$HOME/.gnupg/gpg-agent.conf"
if [ -e "$HOME/.ssh/config" ]; then
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/config"
fi
