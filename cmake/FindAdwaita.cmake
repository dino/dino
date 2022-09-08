include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Adwaita
    PKG_CONFIG_NAME libadwaita-1
    LIB_NAMES libadwaita-1
    INCLUDE_NAMES adwaita.h
    )

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Adwaita
    REQUIRED_VARS Adwaita_LIBRARY
    VERSION_VAR Adwaita_VERSION)
