#!/bin/bash

export ORIGINAL_FOLDER=${PWD}
cd ${PWD}/yolort-builder

if [ ! -f bin/cppwinrt.exe ]; then
    make CPPWINRT_VERSION=2.0.210122.3 bin/cppwinrt.exe
fi

make originals
make --jobs=$(nproc)

mkdir -p ../yolort
cp -r include ../yolort
cd ${ORIGINAL_FOLDER}