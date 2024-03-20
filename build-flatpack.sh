#!/bin/bash
set -e

APP_NAME="im.dino.Dino"
DIST_NAME=${DIST_NAME:-"${APP_NAME}.flatpak"}
DIST_DIR="$PWD/linux-distributives"
BUILD_TEMP_DIR="$DIST_DIR/buildtemp"
BUILD_EXPORT_DIR="$DIST_DIR/export"

msg()
{
    echo -e "\e[32m$1\e[0m"
}

fatal()
{
    echo -e "\e[31m$1\e[0m"
    exit 1
}

getFlatpakDependencies(){
    msg "Installing Flatpak dependencies..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install flathub org.gnome.Sdk//44
    flatpak install flathub org.gnome.Platform//44
    msg "Flatpak dependencies installed"
}

pullSharedModules() {
    msg "Pulling shared modules..."
    git submodule init
    git submodule update
    msg "Shared modules successfully pulled"
}

prepare(){
    getFlatpakDependencies
    pullSharedModules
}

build(){
    msg "Build commencing!"
    rm -rf $BUILD_TEMP_DIR
    flatpak-builder $BUILD_TEMP_DIR "${APP_NAME}.json"
    flatpak build-export $BUILD_EXPORT_DIR $BUILD_TEMP_DIR
    flatpak build-bundle $BUILD_EXPORT_DIR $DIST_NAME $APP_NAME
    msg "Flatpack bundle ready and saved to ${DIST_NAME}"
}

clean(){
    msg "Wiping intermediate files..."
    rm -rf $BUILD_TEMP_DIR $BUILD_EXPORT_DIR
    msg "Cleanup complete!"
}

help()
{
cat << EOF
usage: $0 [OPTION]
  --prepare                  install build dependencies
  --build                    build the project
  --clean                    remove build artifacts
  --help                     show this help

Bundle is saved to ${APP_NAME}.flatpak by default. 
Set DIST_NAME variable to customize output file name:
'DIST_NAME=customname.flatpak $0'

Running without parameters is equivalent to running:
'--prepare', '--build' and '--clean'
EOF
}

case $1 in
    "--prepare" ) prepare ;;
    "--build" ) build ;;
    "--help" ) help ;;
    "--clean" ) clean;;
    "" )
        prepare
        build
        clean
        ;;
    *) fatal "Unknown argument!"
esac
