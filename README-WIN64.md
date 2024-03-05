![Dino (WIN64)](https://dino.im/img/readme_header.svg)
=======

![screenshots](https://dino.im/img/screenshot-main.png)

Build on Windows (x86_64)
------------
- Install and configure the [MSYS2](https://www.msys2.org/) package;
- Go to `MINGW64` environment;
- Clone project:
    ```sh
    git clone https://github.com/mxlgv/dino && cd dino
    ```
- Run the script to install dependencies:
    ```sh
    ./build-win64.sh --prepare
    ```
- Start the build (the builded distribution is available in the `dist-win64` folder):
    ```sh
    ./build-win64.sh
    ```
Note: the build script has some other options, their description can be found using the `--help`.

Resources
---------
- Check out the [Dino website](https://dino.im).
- Join our XMPP channel at `chat@dino.im`.
- The [wiki](https://github.com/dino/dino/wiki) provides additional information.

License
-------
    Dino - Modern Jabber/XMPP Client using GTK+/Vala
    Copyright (C) 2016-2023 Dino contributors

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
