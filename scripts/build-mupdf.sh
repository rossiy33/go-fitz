#!/usr/bin/env bash
set -euo pipefail

# Build mupdf 1.26.11 static libs for linux/amd64 and windows/amd64 (mingw).
# Designed to run inside a Debian/Ubuntu container with:
#   build-essential, mingw-w64, curl, tar, xz-utils, pkg-config
# Inputs:
#   SRC_TGZ=/work/mupdf-1.26.11-source.tar.gz (already downloaded)
#   DEST=/work/out
# Outputs written to $DEST:
#   libmupdf_linux_amd64.a libmupdfthird_linux_amd64.a
#   libmupdf_windows_amd64.a libmupdfthird_windows_amd64.a
#   include/ (copy of mupdf headers)

SRC_TGZ="${SRC_TGZ:-/work/mupdf-1.26.11-source.tar.gz}"
DEST="${DEST:-/work/out}"
WORK="${WORK:-/tmp/mupdf-work}"
JOBS="${JOBS:-$(nproc)}"

mkdir -p "$DEST" "$WORK"
cd "$WORK"

if [ ! -d mupdf-1.26.11-source ]; then
    tar xf "$SRC_TGZ"
fi

XCFLAGS_COMMON="-fPIC -DTOFU_CJK_LANG -DFZ_ENABLE_JS=0"

build_one() {
    local tag="$1" cc="$2" cxx="$3" ar="$4" ranlib="$5" os="$6" extra="$7"
    local src="mupdf-1.26.11-source-$tag"
    rm -rf "$src"
    cp -a mupdf-1.26.11-source "$src"
    pushd "$src" >/dev/null
    make -j"$JOBS" \
        build=release \
        OS="$os" \
        CC="$cc" CXX="$cxx" AR="$ar" RANLIB="$ranlib" \
        HAVE_X11=no HAVE_GLUT=no HAVE_CURL=no \
        XCFLAGS="$XCFLAGS_COMMON $extra" \
        libs
    cp build/release/libmupdf.a "$DEST/libmupdf_${tag}.a"
    cp build/release/libmupdf-third.a "$DEST/libmupdfthird_${tag}.a"
    popd >/dev/null
}

# Linux amd64 (native)
build_one "linux_amd64" "gcc" "g++" "ar" "ranlib" "Linux" ""

# Windows amd64 (mingw cross)
build_one "windows_amd64" \
    "x86_64-w64-mingw32-gcc" \
    "x86_64-w64-mingw32-g++" \
    "x86_64-w64-mingw32-ar" \
    "x86_64-w64-mingw32-ranlib" \
    "MINGW" \
    "-D_WIN32_WINNT=0x0600 -msse4.1 -mssse3"

# Copy headers (from one of the extracted trees — they're identical)
rm -rf "$DEST/include"
mkdir -p "$DEST/include"
cp -a mupdf-1.26.11-source/include/mupdf "$DEST/include/"

ls -la "$DEST"
