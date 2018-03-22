include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Gspell
    PKG_CONFIG_NAME gspell-1
    LIB_NAMES gspell-1
    INCLUDE_NAMES gspell.h
    INCLUDE_DIR_SUFFIXES gspell-1 gspell-1/gspell
    DEPENDS Gtk
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gspell
    REQUIRED_VARS Gspell_LIBRARY
    VERSION_VAR Gspell_VERSION)

