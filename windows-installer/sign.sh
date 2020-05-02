#! /bin/bash

signcode \
 -spc TODO.spc \
 -v TODO.pvk \
 -a sha1 -$ commercial \
 -n Dino \
 -i https://dino.im/ \
 -t http://timestamp.verisign.com/scripts/timstamp.dll \
 -tr 10 \
 dino-installer.exe
