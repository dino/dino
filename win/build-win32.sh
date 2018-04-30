#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

export PATH="/mingw64/bin:/usr/bin:$PATH"

pacman -Q

pacman -R --noconfirm \
       mingw-w64-i686-sqlite3 \
       mingw-w64-i686-python3

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
       mingw64/mingw-w64-x86_64-vala \
       mingw64/mingw-w64-x86_64-gsettings-desktop-schemas

cd $OLDPWD
./configure
make
cd build
mkdir -p dist
cp *.exe *.dll dist
cd dist
ldd dino.exe | grep mingw64 | awk '{print "cp /mingw64/bin/"$1" ."}' | sh
