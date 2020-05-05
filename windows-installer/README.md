# Dino Windows Installer

## Requirements

To create the Dino windows installer you need this:
* nsis (e.g. `apt install nsis` on Debian)
* Dino compiled for windows in input directory
* logo.ico in input directory
	* Download https://dino.im/img/logo.svg
	* Convert it to ico (e.g. `convert -background transparent -define 'icon:auto-resize=16,24,32,64' logo.svg logo.ico` (requires imagemagick)
* Copy `LICENSE` and `LICENSE_SHORT` to the input directory

## Create installer

Simply run `makensis dino.nsi`

## ToDo

* Create a [good looking MUI Installer](https://nsis.sourceforge.io/Docs/Modern%20UI/Readme.html)
* Sign the installer
	* Requires to [buy a certificate](https://comodosslstore.com/resources/free-code-signing-certificate/)
		* Maybe there can be a [free one for open source programs](https://www.codenotary.io/with-codenotary-you-never-have-to-pay-for-code-signing-certificates-again/) - Not yet read thoroughly whether there is a catch.
	* https://stackoverflow.com/questions/9527160/sign-nsis-installer-on-linux-box
	* https://developer.mozilla.org/en-US/docs/Mozilla/Developer_guide/Build_Instructions/Signing_an_executable_with_Authenticode
