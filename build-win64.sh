#!/bin/bash
set -e

DIST_DIR=$PWD/win64-dist
JOBS=$NUMBER_OF_PROCESSORS

msg()
{
    echo -e "\e[32m$1\e[0m"
}

fatal()
{
    echo -e "\e[31m$1\e[0m"
    exit 1
}

prepare()
{
    msg "Installing MINGW64 build dependencies"

    pacman -S --needed --noconfirm \
       mingw64/mingw-w64-x86_64-gcc \
       mingw64/mingw-w64-x86_64-cmake \
       mingw64/mingw-w64-x86_64-ninja \
       mingw64/mingw-w64-x86_64-libsoup3 \
       mingw64/mingw-w64-x86_64-gtk3 \
       mingw64/mingw-w64-x86_64-sqlite3 \
       mingw64/mingw-w64-x86_64-gobject-introspection \
       mingw64/mingw-w64-x86_64-glib2 \
       mingw64/mingw-w64-x86_64-glib-networking \
       mingw64/mingw-w64-x86_64-openssl \
       mingw64/mingw-w64-x86_64-libgcrypt \
       mingw64/mingw-w64-x86_64-libgee \
       mingw64/mingw-w64-x86_64-vala \
       mingw64/mingw-w64-x86_64-gsettings-desktop-schemas \
       mingw64/mingw-w64-x86_64-qrencode \
       mingw64/mingw-w64-x86_64-ntldd-git \
       mingw64/mingw-w64-x86_64-gpgme \
       mingw64/mingw-w64-x86_64-nsis \
       mingw64/mingw-w64-x86_64-fontconfig \
       mingw64/mingw-w64-x86_64-gspell \
       mingw64/mingw-w64-x86_64-enchant \
       mingw64/mingw-w64-x86_64-hunspell \
       mingw64/mingw-w64-x86_64-iso-codes \
       mingw64/mingw-w64-x86_64-gst-plugins-bad \
       mingw64/mingw-w64-x86_64-gst-plugins-good \
       mingw64/mingw-w64-x86_64-gst-plugins-base \
       mingw64/mingw-w64-x86_64-gst-plugins-ugly \
       make \
       zip \
       unzip \
       curl

       msg "Successfully installed!"
}

configure()
{
    msg "Running configuration for Windows"
    ./configure --program-prefix=$DIST_DIR --no-debug --release --disable-fast-vapi --with-libsoup3
    msg "Configured!"
}

build()
{
    msg "Started building on $JOBS threads"
    make -j$JOBS
    msg "Successfully builded!"
}

dist_install()
{
    msg  "Installing Dino in '$DIST_DIR'!"
    make install

    msg "Copying MINGW64 dependencies"
    cp /mingw64/bin/gdbus.exe $DIST_DIR/bin
    cp /mingw64/bin/gspawn-win64-helper.exe $DIST_DIR/bin

    cp /mingw64/bin/libcrypto-*-x64.dll $DIST_DIR/bin/
    cp -r /mingw64/lib/enchant-2 $DIST_DIR/lib
    cp -r /mingw64/lib/gstreamer-1.0 $DIST_DIR/lib
    mkdir -p $DIST_DIR/lib/gdk-pixbuf-2.0/ && cp -r /mingw64/lib/gdk-pixbuf-2.0 $DIST_DIR/lib/
    mkdir -p $DIST_DIR/lib/gio/ && cp -r /mingw64/lib/gio $DIST_DIR/lib/

    list=`find $DIST_DIR -type f \( -name "*.exe" -o -name "*.dll" \) -exec \
    ntldd -R {} + | \
    grep "mingw64" | \
    cut -f1 -d "=" | sort | uniq`
    for a in $list; do
        cp -fv "/mingw64/bin/$a" "$DIST_DIR/bin/" 
    done

    msg "Removing debug information from all EXE and DLL files"
    find $DIST_DIR -iname "*.exe" -exec strip -s {} +
    find $DIST_DIR -iname "*.dll" -exec strip -s {} +

    find $DIST_DIR -iname "*.a" -exec rm {} +

    msg "Removing redudant header files"
    rm -rf $DIST_DIR/include

    msg "Copy icons, themes, locales and fonts"
    cp -rf /mingw64/share/xml $DIST_DIR/share
    mkdir -p $DIST_DIR/etc/fonts && cp -r /mingw64/etc/fonts $DIST_DIR/etc/
    mkdir -p $DIST_DIR/share/icons && cp -r /mingw64/share/icons $DIST_DIR/share/
    mkdir -p $DIST_DIR/share/glib-2.0/schemas && cp -rf /mingw64/share/glib-2.0/schemas $DIST_DIR/share/glib-2.0/

    msg "Downloading spell check files for RU and EN (USA)"
    mkdir -p $DIST_DIR/share/hunspell
    curl -L -o $DIST_DIR/share/hunspell/ru.aff https://github.com/elastic/hunspell/raw/master/dicts/ru/ru.aff
    curl -L -o $DIST_DIR/share/hunspell/ru.dic https://github.com/elastic/hunspell/raw/master/dicts/ru/ru.dic
    curl -L -o $DIST_DIR/share/hunspell/en_US.aff https://github.com/elastic/hunspell/raw/master/dicts/en_US/en_US.aff
    curl -L -o $DIST_DIR/share/hunspell/en_US.dic https://github.com/elastic/hunspell/raw/master/dicts/en_US/en_US.dic

    msg "Successfully installed!"
}

clean()
{
    rm -rf build $DIST_DIR
    msg "Build artifacts removed successfull!"
}

help()
{
cat << EOF
usage: $0 [OPTION]
  --prepare                  install build dependencies
  --configure                configure the project
  --build                    build the project
  --dist-install             install the builded project
  --clean                    remove build artifacts
  --help                     show this help

Running without parameters is equivalent to running:
'--configure', '--build' and '--dist-install'
EOF
}

if [[ $(uname) != "MINGW64_NT"* ]]; then
    fatal "This is not a MINGW64 environment!"
fi

case $1 in
    "--prepare" ) prepare ;;
    "--configure" ) configure ;;
    "--build" ) build ;;
    "--dist-install" ) dist_install ;;
    "--clean" ) clean ;;
    "--help" ) help ;;
    "" )
        configure
        build
        dist_install
        ;;
    *) fatal "Unknown argument!"
esac
