#!/bin/sh
set -eu

# Build GNU Emacs 31.1 on Debian 13 (Trixie).
version=31.1
sha256=1da5790d9580c81932b5bf700633114468da7b3412d69faa767daebf974f4586
prefix="$HOME/opt/emacs-$version"
work="$HOME/tmp/emacs-build-$version"
archive="$work/emacs-$version.tar.xz"

# Runtime libraries stay installed; do not autoremove build dependencies.
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    build-essential curl xz-utils pkg-config texinfo \
    libgtk-3-dev libgnutls28-dev libxml2-dev libsqlite3-dev \
    libtree-sitter-dev libgccjit-14-dev libharfbuzz-dev libncurses-dev \
    libjpeg-dev libpng-dev libgif-dev libtiff-dev \
    librsvg2-dev libwebp-dev libxpm-dev

if [ ! -x "$prefix/bin/emacs" ]; then
    mkdir -p "$work/build"
    if [ ! -f "$archive" ]; then
        curl -fL --retry 3 \
            "https://ftp.gnu.org/gnu/emacs/emacs-$version.tar.xz" \
            -o "$archive"
    fi
    printf '%s  %s\n' "$sha256" "$archive" | sha256sum -c -
    if [ ! -d "$work/emacs-$version" ]; then
        tar -xf "$archive" -C "$work"
    fi

    cd "$work/build"
    "$work/emacs-$version/configure" \
        --prefix="$prefix" \
        --with-x-toolkit=gtk3 \
        --with-tree-sitter \
        --with-native-compilation
    make -j "$(nproc)"
    make install
fi

mkdir -p "$HOME/opt/bin"
for name in emacs emacsclient etags; do
    link="$HOME/opt/bin/$name"
    if [ -e "$link" ] && [ ! -L "$link" ]; then
        printf 'Refusing to replace non-symlink: %s\n' "$link" >&2
        exit 1
    fi
    ln -sfn "../emacs-$version/bin/$name" "$link"
done

"$prefix/bin/emacs" --batch -Q --eval \
    '(princ (format "Emacs %s | native=%s | tree-sitter=%s\n" emacs-version (native-comp-available-p) (treesit-available-p)))'
printf 'Installed to %s\nAdd %s to PATH ahead of /usr/bin.\n' "$prefix" "$HOME/opt/bin"
