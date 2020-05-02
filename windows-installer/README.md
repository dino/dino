# Dino Windows Installer

## Requirements

To create the Dino windows installer you need this:
* nsis (e.g. `apt install nsis` on Debian)
* Dino compiled for windows in input directory
* logo.ico in input directory
	* Download https://dino.im/img/logo.svg
	* Convert it to ico (e.g. `onvert -background transparent -define 'icon:auto-resize=16,24,32,64' logo.svg logo.ico` (requires imagemagick)

## Create installer

Simply run `makensis dino.nsi`
