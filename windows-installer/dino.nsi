Unicode True

!define MUI_PRODUCT "Dino"
!define MUI_PRODUCT_NAME ${MUI_PRODUCT}
!define MUI_BRANDINGTEXT ${MUI_PRODUCT}
!define PRODUCT_WEBSITE "https://dino.im"
!define MUI_ICON "input/logo.ico"
!define ICON "input/logo.ico"
!define MUI_COMPONENTSPAGE_NODESC

# Installation types
InstType "OpenPGP support" IT_PGP

# Modern Interface
!include "MUI2.nsh"
!insertmacro MUI_PAGE_LICENSE "input/LICENSE_SHORT"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!include "english.nsh"
!include "german.nsh"

Name ${MUI_PRODUCT}
BrandingText "Communicating happiness"

# define installer name
OutFile "dino-installer.exe"
 
# set install directory
InstallDir $PROGRAMFILES64\dino

Section 

# Install all files but openpgp.dll
SetOutPath $INSTDIR
File /r input/bin
File input/LICENSE
File input/logo.ico
File input/logo.svg
File /r input/share
SetOutPath $INSTDIR\lib
File /r input/lib/gio
File /r input/lib/gdk-pixbuf-2.0
SetOutPath $INSTDIR\lib\dino\plugins
File input/lib/dino/plugins/http-files.dll
File input/lib/dino/plugins/omemo.dll
File input/lib/dino/plugins/win32-fonts.dll

# define uninstaller name
WriteUninstaller $INSTDIR\uninstaller.exe
 
# Create a shortcut for startmenu
CreateDirectory "$SMPROGRAMS\Dino"
CreateShortcut "$SMPROGRAMS\Dino\Dino.lnk" "$INSTDIR\bin\dino.exe" "" "$INSTDIR\logo.ico"
CreateShortcut "$SMPROGRAMS\Dino\Uninstaller.lnk" "$INSTDIR\uninstaller.exe"
CreateShortcut "$SMPROGRAMS\Dino\License.lnk" "$INSTDIR\LICENSE" "" "notepad.exe" 0
CreateShortcut "$SMPROGRAMS\Dino\Dino website.lnk" "https://dino.im" "" "$INSTDIR\logo.ico"

SectionEnd

Section "OpenPGP support"
SectionInstType ${IT_PGP}
SetOutPath $INSTDIR/lib/dino/plugins
File input/lib/dino/plugins/openpgp.dll
SectionEnd
 
# Uninstaller section
Section "Uninstall"

# Delete startmenu folder
RMDir /r "$SMPROGRAMS\Dino"

# Always delete uninstaller first
Delete $INSTDIR\uninstaller.exe
 
# now delete installed file
Delete $INSTDIR\*

# Delete the directory
RMDir /r $INSTDIR
SectionEnd
