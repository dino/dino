#!/bin/bash
export FILE_NAME=cppwinrt-2.0.210122.3+windows-10.0.19041+yolort-835cd4e.zip
export ORIGINAL_FOLDER=${PWD}

mkdir -p yolort && \
    cd yolort && \
    curl -L -O https://github.com/LAGonauta/YoloRT/releases/download/v1.0.0/${FILE_NAME} && \
    echo "675a6d943c97b4acdbfaa473f68d3241d1798b31a67b5529c8d29fc0176a1707 ${FILE_NAME}" | sha256sum --check --status && \
    unzip -o ${FILE_NAME} && \
    rm ${FILE_NAME} && \
    cd ${ORIGINAL_FOLDER}
