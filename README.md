#Dino
![screenshots](http://i.imgur.com/n9caTuJ.png)

##Build
    ./configure
    make
    glib-compile-schemas client/data
    env GSETTINGS_SCHEMA_DIR=client/data/ build/dino
