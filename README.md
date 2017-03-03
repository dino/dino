#Dino
![screenshots](http://i.imgur.com/JSHwxNf.png)

##Build
    ./configure
    make
    glib-compile-schemas client/data
    env GSETTINGS_SCHEMA_DIR=client/data/ build/dino
