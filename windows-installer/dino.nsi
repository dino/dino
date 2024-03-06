Unicode True

RequestExecutionLevel user
SetCompressor /SOLID lzma

!define MUI_PRODUCT "Dino"
!define MUI_PRODUCT_NAME ${MUI_PRODUCT}
!define MUI_BRANDINGTEXT ${MUI_PRODUCT}
!define PRODUCT_WEBSITE "https://dino.im"
!define MUI_ICON "win64-dist/dino.ico"
!define ICON "win64-dist/dino.ico"
!define MUI_COMPONENTSPAGE_NODESC

# Modern Interface
!include "MUI2.nsh"
!insertmacro MUI_PAGE_LICENSE "LICENSE_SHORT"
!insertmacro MUI_PAGE_INSTFILES
!include "english.nsh"

Name ${MUI_PRODUCT}
BrandingText "Communicating happiness"

# define installer name
OutFile "dino-installer.exe"
 
# set install directory
InstallDir $APPDATA\Dino

Section 

# Install all files
SetOutPath $INSTDIR
File /r win64-dist\*.*

# define uninstaller name
WriteUninstaller $INSTDIR\uninstaller.exe

# Create a shortcut for startmenu
CreateDirectory "$SMPROGRAMS\Dino"
CreateShortcut "$SMPROGRAMS\Dino\Dino.lnk" "$INSTDIR\bin\dino.exe" "" "$INSTDIR\dino.ico"
CreateShortcut "$SMPROGRAMS\Dino\Uninstaller.lnk" "$INSTDIR\uninstaller.exe"
CreateShortcut "$SMPROGRAMS\Dino\License.lnk" "notepad.exe" "$INSTDIR\LICENSE"
CreateShortcut "$SMPROGRAMS\Dino\Dino website.lnk" "https://dino.im" "" "$INSTDIR\dino.ico"

# Create a shortcut for desktop
CreateShortCut "$DESKTOP\Dino.lnk" "$INSTDIR\bin\dino.exe" "" "$INSTDIR\dino.ico"

# set application ID
# No "ApplicationID" plugin for NSIS MINGW64
# ApplicationID::Set "$SMPROGRAMS\Dino\Dino.lnk" "Dino" "true"

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
