include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Secret
    PKG_CONFIG_NAME libsecret-1
    LIB_NAMES libsecret-1
    INCLUDE_NAMES libsecret/secret.h
    INCLUDE_DIR_SUFFIXES libsecret-1 libsecret-1/include
    DEPENDS GLib Gio
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Secret
    REQUIRED_VARS Secret_LIBRARY
    VERSION_VAR Secret_VERSION)
