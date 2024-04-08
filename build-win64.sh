#!/bin/bash

set -eu

PROJ_DIR=$PWD
DIST_DIR=${PROJ_DIR}/windows-installer/win64-dist
BUILD_DIR=$PROJ_DIR/build
JOBS=$NUMBER_OF_PROCESSORS
build_sys='cmake'

msg()
{
    echo -e "\e[32m$1\e[0m"
}

fatal()
{
    echo -e "\e[31m$1\e[0m"
    exit 1
}

download_yolort()
{
    file_name=cppwinrt-2.0.210122.3+windows-10.0.19041+yolort-835cd4e.zip
    yolort_dir="$PROJ_DIR/plugins/windows-notification/yolort"

    rm -rf "$yolort_dir"
    mkdir "$yolort_dir"
    curl -L -o "$file_name" "https://github.com/LAGonauta/YoloRT/releases/download/v1.0.0/$file_name"
    echo "675a6d943c97b4acdbfaa473f68d3241d1798b31a67b5529c8d29fc0176a1707 $file_name" | sha256sum --check --status
    unzip -o "$file_name" -d "$yolort_dir"
    rm -f "$file_name"
}

download_gtk4_git()
{
    # FIXME: The bug fix https://gitlab.gnome.org/GNOME/gtk/-/issues/3749 is currently only available in the main branch, 
    # so GTK4 was builded from it. Needs to be replaced with a package from the MSYS2 repository when the changes get there.
    url="https://github.com/mxlgv/mingw-w64-gtk4-git/releases/download/rel1"
    gtk_pkg="mingw-w64-x86_64-gtk4-git-4.14.1.r62.gb1eed1c153-1-any.pkg.tar.zst"
    gtk_gstreamer_pkg="mingw-w64-x86_64-gtk4-media-gstreamer-git-4.14.1.r62.gb1eed1c153-1-any.pkg.tar.zst"

    curl -L -o "$gtk_pkg" "$url/$gtk_pkg"
    curl -L -o "$gtk_gstreamer_pkg" "$url/$gtk_gstreamer_pkg"

    pacman -U --needed --noconfirm "$gtk_pkg" "$gtk_gstreamer_pkg"
}

prepare()
{
    msg "Installing MINGW64 build dependencies"

    pacman -S --needed --noconfirm \
       mingw64/mingw-w64-x86_64-gcc \
       mingw64/mingw-w64-x86_64-cmake \
       mingw64/mingw-w64-x86_64-ninja \
       mingw64/mingw-w64-x86_64-libadwaita \
       mingw64/mingw-w64-x86_64-sqlite3 \
       mingw64/mingw-w64-x86_64-openssl \
       mingw64/mingw-w64-x86_64-libgcrypt \
       mingw64/mingw-w64-x86_64-libgee \
       mingw64/mingw-w64-x86_64-vala \
       mingw64/mingw-w64-x86_64-gsettings-desktop-schemas \
       mingw64/mingw-w64-x86_64-qrencode \
       mingw64/mingw-w64-x86_64-ntldd-git \
       mingw64/mingw-w64-x86_64-gpgme \
       mingw64/mingw-w64-x86_64-fontconfig \
       mingw64/mingw-w64-x86_64-iso-codes \
       mingw64/mingw-w64-x86_64-gstreamer \
       mingw64/mingw-w64-x86_64-gst-plugins-bad \
       mingw64/mingw-w64-x86_64-gst-plugins-good \
       mingw64/mingw-w64-x86_64-gst-plugins-base \
       mingw64/mingw-w64-x86_64-gst-plugins-ugly \
       mingw64/mingw-w64-x86_64-nsis \
       mingw64/mingw-w64-x86_64-libsignal-protocol-c \
       mingw64/mingw-w64-x86_64-icu \
       mingw64/mingw-w64-x86_64-webrtc-audio-processing \
       mingw64/mingw-w64-x86_64-meson \
       git \
       make \
       unzip \
       curl

    msg "Downloading and install git versions of gtk4 and gtk4-media-gstreamer packages"
    download_gtk4_git

    msg "Successfully installed!"

    msg "Download YoloRT headers"
    download_yolort
    msg "Successfully downloaded!"

}

configure_cmake()
{
    msg "Running configuration for Windows"
    ./configure --program-prefix="$DIST_DIR" --no-debug --release --disable-fast-vapi --with-libsoup3 --with-tests
    msg "Configured!"
}

build_cmake()
{
    msg "Started building on $JOBS threads"
    make -j"$JOBS"
    msg "Successfully builded!"
    msg "Installing Dino .."
    make install
}

test_cmake()
{
    msg "Run tests"
    make test
}

configure_meson()
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

build_meson()
{
    meson compile -C $BUILD_DIR
    meson install -C $BUILD_DIR
}

test_meson()
{
    msg "Run tests"
    meson test -C $BUILD_DIR
}

dist_install()
{
    _dist_arg=${1:-$DIST_DIR}

    msg "Generate dino-with-console.exe"
    cp -f "$_dist_arg/bin/dino.exe" "$_dist_arg/bin/dino-with-console.exe"
    # IMAGE_SUBSYSTEM_WINDOWS_CUI = 0x0003
    # SUBSYSTEM_OFFSET = 0xDC (220)
    printf '\x03\x00' | dd of="$_dist_arg/bin/dino-with-console.exe" bs=1 seek=220 count=2 conv=notrunc

    msg "Copying MINGW64 dependencies"
    cp /mingw64/bin/gdbus.exe "$_dist_arg/bin"
    cp /mingw64/bin/gspawn-win64-helper.exe "$_dist_arg/bin"

    cp /mingw64/bin/libcrypto-*-x64.dll "$_dist_arg/bin/"
    cp -r /mingw64/lib/gstreamer-1.0 "$_dist_arg/lib"
    mkdir -p "$_dist_arg/lib/gdk-pixbuf-2.0/" && cp -r /mingw64/lib/gdk-pixbuf-2.0 "$_dist_arg/lib/"
    mkdir -p "$_dist_arg/lib/gio/" && cp -r /mingw64/lib/gio "$_dist_arg/lib/"

    list=`find "$_dist_arg" -type f \( -name "*.exe" -o -name "*.dll" \) -exec \
    ntldd -R {} + | \
    grep "mingw64" | \
    cut -f1 -d "=" | sort | uniq`
    for a in $list; do
        cp -fv "/mingw64/bin/$a" "$_dist_arg/bin/"
    done

    msg "Removing debug information from all EXE and DLL files"
    find "$_dist_arg" -iname "*.exe" -exec strip -s {} +
    find "$_dist_arg" -iname "*.dll" -exec strip -s {} +

    find "$_dist_arg" -iname "*.a" -exec rm {} +

    msg "Removing redudant header files"
    rm -rf "$_dist_arg/include"

    msg "Copy LICENSE"
    cp -f "$PWD/LICENSE" "$_dist_arg/LICENSE"

    msg "Copy icons, themes, locales and fonts"
    cp -f "$PWD/main/dino.ico" "$_dist_arg/dino.ico"
    cp -rf "/mingw64/share/xml" "$_dist_arg/share"
    mkdir -p "$_dist_arg/etc/fonts" && cp -r /mingw64/etc/fonts "$_dist_arg/etc/"
    mkdir -p "$_dist_arg/share/icons" && cp -r /mingw64/share/icons "$_dist_arg/share/"
    mkdir -p "$_dist_arg/share/glib-2.0/schemas" && cp -rf /mingw64/share/glib-2.0/schemas "$_dist_arg/share/glib-2.0/"

    msg "Successfully installed!"
}

build_installer()
{
    msg "Building an installer for Windows using NSIS"
    cd windows-installer
    makensis dino.nsi
    msg "Installer successfully builded!"
    cd ..
}

clean()
{
    rm -rf $BUILD_DIR $DIST_DIR
    msg "Build artifacts removed successfull!"
}

help()
{
    cat << EOF
	Script to build Dino for windows using cmake or meson build-system.
	By default it will be build using build directory
	  $BUILD_DIR
	and installed to
	  $DIST_DIR

	Usage: $0 [option]

        Note: you may set the multiple options, but be sure that they will be
	      processed sequentially (one-by-one), e.g. command
                $0 -s meson -c -b
              will run buld config and _after_ that run build using meson, while
                $0 -c -b -s meson
              will run cmake-based configure & build commands and the -s option
              wont have any effect. And the one
                $0 -b -s meson -c
	      is incorrect, as it willtry to run build(for cmake), then configure
              with for meson build.

	--help, -h
		print this help message.

	--set-buildsys, -s
                set (specify) build system name to be used
                possible options are: cmake or meson

	--prepare, -p
		install build dependencies. may be done once.

	--configure, -c
		configure build using selected build-system.

	--build, -b
		invoke build.

	--test, -t
		run tests.

	--reconfig, -r
		reconfigure project, if minor changes were
		done to build config files but build has been
		configured already (only for meson!).

	--whipe, -w
		remove build artifacts from $BUILD_DIR

	--verbose, -v
		verbose output enable.

        --dist-install, -i
               install the builded project along with its'
               dependencies.

        --build-installer
               build installer (using NSIS)

        Running without parameters will run configure, build & install
        using cmake-based build-system as default one.
EOF
}

if [[ "$(uname)" != "MINGW64_NT"* ]]; then
    fatal "This is not a MINGW64 environment!"
fi

# no options provided,simply build with defaults
if [[ $# == 0 ]]; then
	prepare
	configure_${build_sys}
	build_${build_sys}
	dist_install

	exit 0
fi

while [[ $# > 0 ]];
do
	case $1 in
		--prepare|-p)
			prepare
			;;
		--configure|-c)
			configure_${build_sys}
			;;
		--build|-b)
			build_${build_sys}
			;;
		--test|-t)
			test_${build_sys}
			;;
		--reconfig|-r)
			configure_${build_sys} reconfig
			;;
		--whipe|-w)
			clean
			;;
		--dist-install|-i)
			dist_install
			;;
		--verbose|-v)
			set -xv
			;;
		--help|-h)
			help
			exit 0;
			;;
		--build-installer)
			build_installer
			;;
		--set-buildsys|-s)
			if [ x"$2" != x"cmake" -a x"$2" != x"meson" ]; then
				fatal "Improper build system selected: ${2}!"
				exit 1;
			fi
                        build_sys=$2
                        shift
			;;
		-*)
			echo "Unknown option $1"
			exit 1
			;;
	esac
	shift
done
