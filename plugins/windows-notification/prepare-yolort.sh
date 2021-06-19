#!/bin/bash
export FILE_NAME=cppwinrt-2.0.210122.3+windows-10.0.19041+yolort-835cd4e.zip
export ORIGINAL_FOLDER=${PWD}

mkdir -p yolort && \
    cd yolort && \
    curl -L -O https://github.com/LAGonauta/YoloRT/releases/download/v1.0.0/${FILE_NAME} && \
    unzip -o ${FILE_NAME} && \
    rm ${FILE_NAME} && \
    cd ${ORIGINAL_FOLDER}
