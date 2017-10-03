![Dino](https://cdn.rawgit.com/fiaxh/3cb1391c5a94443098d004b4bf7c712c/raw/62f6a5e7de8402a0a89ffc73e8d1ed170054051c/dino-writing.svg)
=======

![screenshots](https://i.imgur.com/1KqLqDV.png)

Build
-----

**Build-time dependencies**

* CMake
* C compiler
* gettext
* ninja(-build) (recommend)
* valac (≥ 0.30)

**Run-time dependencies**

* GLib (≥ 2.38)
* glib-networking
* GTK (≥ 3.22)
* GPGME (For the OpenPGP plugin)
* libgee-0.8 (≥ 0.10)
* libgcrypt (For the OMEMO plugin)
* libsoup (For the HTTP files plugin)
* SQLite3

**Instructions**

    ./configure
    make
    build/dino

Resources
---------
Join our conference room at [chat@dino.im](xmpp:chat@dino.im?join)

Please refer to [the wiki](https://github.com/dino/dino/wiki) for further information.

License
-------
    Dino - Modern Jabber/XMPP Client using GTK+/Vala
    Copyright (C) 2017 Dino contributors

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
