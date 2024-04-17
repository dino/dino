Here are the instructions to anyone whom wants to try the build themselves.
It is assumed that you have `brew` installed, know your way around terminal, and generally understand what you're doing.

## Build

1. Start with an already existing build instructions of the original project:

`https://github.com/dino/dino/wiki/macOS`

2. On step 4, replace the path to the upstream repo with this one:

```
git clone https://github.com/mxlgv/dino
cd dino
```

3. On step 5 run `./configure --with-libsoup3`.

4. Continue the build according to the original instructions.

## Install with Brew

To build Dino using this formula, follow these instructions:

```
brew tap mxlgv/homebrew-dino
brew install mxlgv/homebrew-dino/dino
```

You can start the Dino client installed via homebrew with the following command:

```
./opt/homebrew/Cellar/dino/3/bin/dino
```

You can create a shortcut with a symbolic link pointing to this file, so that you can open it in a more convenient way.

If you encounter an error related to rpath, you need to add `DYLD_LIBRARY_PATH` to the environment variable:

```
export DYLD_LIBRARY_PATH=/opt/homebrew/Cellar/dino/3/lib
```

## Notifications

There is a draft PR which can be used to enable notifications: https://github.com/mxlgv/dino/pull/45

## Start Dino

In order to run Dino, just run in the build folder:

```
./dino
```
