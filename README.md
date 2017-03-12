#Dino
![screenshots](http://i.imgur.com/xIKPEFF.png)

##Build
    ./configure
    make
    glib-compile-schemas libdino/data
    env GSETTINGS_SCHEMA_DIR=libdino/data/ build/dino
