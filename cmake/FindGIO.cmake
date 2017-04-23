include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GIO
    PKG_CONFIG_NAME gio-2.0
    LIB_NAMES gio-2.0
    INCLUDE_NAMES gio/gio.h
    INCLUDE_DIR_SUFFIXES glib-2.0 glib-2.0/include
    DEPENDS GObject
)

if(GIO_FOUND AND NOT GIO_VERSION)
    # TODO
    find_package(GLib ${GLib_GLOBAL_VERSION})
    set(GIO_VERSION ${GLib_VERSION})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GIO
    REQUIRED_VARS GIO_LIBRARY
    VERSION_VAR GIO_VERSION)