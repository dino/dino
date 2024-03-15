#!/bin/bash
set -e

getFlatpackDependencies(){
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install flathub org.gnome.Sdk//44
    flatpak install flathub org.gnome.Platform//44
}

prepareModules(){
    git submodule init
    git submodule update
}

build(){
    FP_TEMP_BUILD_DIR=$(mktemp -d)
    FP_OUTDIR="builds"
    flatpak-builder ${FP_TEMP_BUILD_DIR} im.dino.Dino.json
    flatpak build-export $FP_OUTDIR $FP_TEMP_BUILD_DIR
    flatpak build-bundle $FP_OUTDIR dino.flatpak
}

getFlatpackDependencies
prepareModules
build