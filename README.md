Dino
====

![screenshots](http://i.imgur.com/xIKPEFF.png)

Install
-------
| OS                  | Package|
| --------------------| ------ |
| Arch Linux          | [`dino-git`](https://aur.archlinux.org/packages/dino-git/) (AUR)         |
| Fedora ≥ 25         | [`dino`](https://copr.fedorainfracloud.org/coprs/larma/dino/) (copr)     |
| openSUSE Tumbleweed | [`dino`](https://build.opensuse.org/package/show/home:jubalh/dino) (OBS) |

**Dependencies**

* GLib (≥ 2.38)
* GTK (≥ 3.22)
* GPGME (For the OpenPGP plugin)
* libgee-0.8 (≥ 0.10)
* libgcrypt (For the OMEMO plugin)
* libnotify
* SQLite3

Build
-----

**Build-time dependencies**

* CMake
* C compiler
* gettext
* ninja(-build) (recommend)
* valac (≥ 0.30)

**Instructions**

    ./configure
    make
    build/dino

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
