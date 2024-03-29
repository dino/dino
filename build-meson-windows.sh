#!/bin/bash

set -eu

PROJ_DIR=$PWD
BUILD_DIR=$PROJ_DIR/build/meson
DIST_DIR=$PROJ_DIR/windows-installer/win64-meson

prepare()
{
    if [ -d ${PROJ_DIR}/plugins/windows-notification/yolort ]; then
	echo "No need to re-download packages & yolort sources."
    else
        bash build-win64.sh --prepare
    fi
}

configure()
{
    arg=${1:-"none"}
    encr=${2:-"auto"}
    local cmd=""
    if [ x"${arg}" == x"reconfig" ]; then
	    cmd=--reconfigure
    fi
    mkdir -p $BUILD_DIR
    meson setup ${cmd} --prefix "$DIST_DIR" \
	    -D crypto-backend=${encr} \
	    -D plugin-ice=enabled \
	    $PROJ_DIR $BUILD_DIR
}

build()
{
    cd $BUILD_DIR && ninja
    ninja install
}

clean()
{
    rm -rf $DIST_DIR $BUILD_DIR
}

help()
{
cat <<  EOF
	Script to build Dino for windows using meson build-system.
	By default it will be build using build directory
	  $BUILD_DIR
	and installed to
	  $DIST_DIR

	Usage: $0 [option]

	--prepare, -p
		install build dependencies. may be done once.

	--configure, -c
		configure build using meson.

	--build, -b
		invoked build.

	--reconfig, -r
		reconfigure project, if minor changes were
		done tobuild config files but build has been
		configured already.

	--whipe, -w
		remove build artifacts from $BUILD_DIR

	--verbose, -v
		verbose output enable.

	--help, -h
		print  this help message.

EOF
}

# Main

if [[ "$(uname)" != "MINGW64_NT"* ]]; then
    fatal "This is not a MINGW64 environment!"
fi

if [[ $# == 0 ]]; then
	prepare
	configure
	build

	exit 0
fi

while [[ $# > 0 ]];
do
	case $1 in
		--prepare|-p)
			prepare
			;;
		--configure|-c)
			configure
			;;
		--build|-b)
			build
			;;
		--reconfig|-r)
			configure reconfig
			;;
		--whipe|-w)
			clean
			;;
		--verbose|-v)
			set -xv
			;;
		--help|-h)
			help
			;;
		*)
			echo "Unkown option $1"
			exit 1
			;;
	esac
	shift
done
