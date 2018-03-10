#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

export PATH="/mingw64/bin:/usr/bin:$PATH"

# pacman -Syuu --needed --noconfirm --ask=127
pacman -S --noconfirm --needed \
       mingw64/mingw-w64-x86_64-cmake \
       mingw64/mingw-w64-x86_64-ninja \
       mingw64/mingw-w64-x86_64-libsoup \
       mingw64/mingw-w64-x86_64-gpgme \
       mingw64/mingw-w64-x86_64-gtk3 \
       mingw64/mingw-w64-x86_64-sqlite3 \
       mingw64/mingw-w64-x86_64-gobject-introspection \
       mingw64/mingw-w64-x86_64-glib2 \
       mingw64/mingw-w64-x86_64-glib-networking \
       mingw64/mingw-w64-x86_64-libgcrypt \
       mingw64/mingw-w64-x86_64-libgee \
       mingw64/mingw-w64-x86_64-pkg-config \
       mingw64/mingw-w64-x86_64-vala

cd /c/projects/dino
./configure
make
cd build
mkdir dist
cp *.exe *.dll dist
cd dist
ldd dino.exe | grep mingw64 | awk '{print "cp /mingw64/bin/"$1" ."}' | sh
