Unicode True

!define MUI_PRODUCT "Dino"
!define MUI_PRODUCT_NAME ${MUI_PRODUCT}
!define MUI_BRANDINGTEXT ${MUI_PRODUCT}
!define PRODUCT_WEBSITE "https://dino.im"
!define MUI_ICON "input/logo.ico"
!define ICON "input/logo.ico"

# Modern Interface
!include "MUI2.nsh"
!insertmacro "MUI_PAGE_LICENSE" "input/LICENSE_SHORT"
!insertmacro MUI_PAGE_INSTFILES

Name ${MUI_PRODUCT}
BrandingText "Communicating happiness"

# define installer name
OutFile "dino-installer.exe"
 
# set install directory
InstallDir $PROGRAMFILES64\dino
 
# default section start
Section
 
# Install binary and DLLs
SetOutPath $INSTDIR\bin
File input/*.dll input/dino.exe

# Install the libs and shared files 
SetOutPath $INSTDIR
File /r /x dino.exe /x plugins /x ./*.dll input/*

# Install the plugins
SetOutPath $INSTDIR\lib\dino\plugins
File input/plugins/*
 
# define uninstaller name
WriteUninstaller $INSTDIR\uninstaller.exe
 
# Create a shortcut for startmenu
CreateShortcut "$SMPROGRAMS\dino.lnk" "$INSTDIR\bin\dino.exe" "" "$INSTDIR\logo.ico"

# default section end
SectionEnd
 
# Uninsaller section
Section "Uninstall"
 
# Always delete uninstaller first
Delete $INSTDIR\uninstaller.exe
 
# now delete installed file
Delete $INSTDIR\*

# Delete the directory
RMDir /r $INSTDIR
SectionEnd
