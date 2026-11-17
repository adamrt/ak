#!/bin/sh
set -eu

# Install an official Go binary release on Debian.
# Update the checksums together with VERSION (https://go.dev/dl/).
VERSION=1.27.3
SHA256_AMD64=65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40
SHA256_ARM64=a06e99309dbcbdca1a8ccd2282c3ee146e55930886e26b4f1193269587165f49
OPT="$HOME/opt"
PREFIX="$OPT/go"
WORK="$HOME/tmp/go-build-$VERSION"
DOWNLOAD_URL="https://go.dev/dl"
# DOWNLOAD_URL="https://mirror.nju.edu.cn/golang"

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

cleanup() {
    # Put the previous install back if the final rename failed.
    if [ -n "$STAGE" ] && { [ -d "$STAGE/previous" ] || [ -L "$STAGE/previous" ]; } &&
        [ ! -e "$PREFIX" ] && [ ! -L "$PREFIX" ]; then
        mv -T -- "$STAGE/previous" "$PREFIX" ||
            die "Previous installation retained at $STAGE/previous"
    fi
    rm -rf -- "$STAGE" "$SCRATCH"
}

[ "$(uname -s)" = Linux ] || die "This installer is for Linux."
case "$(uname -m)" in
    x86_64)
        ARCH=amd64
        SHA256=$SHA256_AMD64
        ;;
    aarch64)
        ARCH=arm64
        SHA256=$SHA256_ARM64
        ;;
    *) die "This installer supports Linux x86-64 and ARM64." ;;
esac

ARCHIVE="go$VERSION.linux-$ARCH.tar.gz"
EXPECTED="go version go$VERSION linux/$ARCH"

mkdir -p "$OPT"
exec 9>"$OPT/.install-go.lock"
flock 9
unset GOROOT

if [ ! -L "$PREFIX" ] && [ -x "$PREFIX/bin/go" ] &&
    [ "$(GOTOOLCHAIN=local "$PREFIX/bin/go" version 2>/dev/null)" = "$EXPECTED" ]; then
    printf 'Go %s is already installed at %s\n' "$VERSION" "$PREFIX"
    exit 0
fi

if [ -e "$PREFIX" ] && [ ! -L "$PREFIX" ]; then
    [ -d "$PREFIX" ] && [ -f "$PREFIX/VERSION" ] && [ -x "$PREFIX/bin/go" ] ||
        die "Refusing to replace an unrecognized path: $PREFIX"
fi

for TOOL in curl sha256sum tar; do
    command -v "$TOOL" >/dev/null 2>&1 || die "Missing dependency: $TOOL"
done

mkdir -p "$WORK"
SCRATCH=$(mktemp -d "$WORK/install.XXXXXXXX")
STAGE=
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

if [ ! -f "$WORK/$ARCHIVE" ] ||
    ! printf '%s  %s\n' "$SHA256" "$WORK/$ARCHIVE" | sha256sum --check --status; then
    curl -fL --progress-bar --retry 3 "$DOWNLOAD_URL/$ARCHIVE" -o "$SCRATCH/$ARCHIVE"
    printf '%s  %s\n' "$SHA256" "$SCRATCH/$ARCHIVE" | sha256sum --check
    mv -T -- "$SCRATCH/$ARCHIVE" "$WORK/$ARCHIVE"
fi
tar -xzf "$WORK/$ARCHIVE" -C "$SCRATCH"

# Stage the final rename on the same filesystem as the install directory.
STAGE=$(mktemp -d "$OPT/.install-go.XXXXXXXX")
mv -T -- "$SCRATCH/go" "$STAGE/go"
[ "$(GOTOOLCHAIN=local "$STAGE/go/bin/go" version)" = "$EXPECTED" ] ||
    die "Downloaded toolchain did not report the expected Go version."

if [ -d "$PREFIX" ] || [ -L "$PREFIX" ]; then
    mv -T -- "$PREFIX" "$STAGE/previous"
fi
mv -T -- "$STAGE/go" "$PREFIX"
printf 'Installed to %s\n' "$PREFIX"
