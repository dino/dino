include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GDKPixbuf2
    PKG_CONFIG_NAME gdk-pixbuf-2.0
    LIB_NAMES gdk_pixbuf-2.0
    INCLUDE_NAMES gdk-pixbuf/gdk-pixbuf.h
    INCLUDE_DIR_SUFFIXES gdk-pixbuf-2.0 gdk-pixbuf-2.0/include
    DEPENDS GLib
)

if(GDKPixbuf2_FOUND AND NOT GDKPixbuf2_VERSION)
    find_file(GDKPixbuf2_FEATURES_HEADER "gdk-pixbuf/gdk-pixbuf-features.h" HINTS ${GDKPixbuf2_INCLUDE_DIRS})
    mark_as_advanced(GDKPixbuf2_FEATURES_HEADER)

    if(GDKPixbuf2_FEATURES_HEADER)
        file(STRINGS "${GDKPixbuf2_FEATURES_HEADER}" GDKPixbuf2_VERSION REGEX "^#define GDK_PIXBUF_VERSION \\\"[^\\\"]+\\\"")
        string(REGEX REPLACE "^#define GDK_PIXBUF_VERSION \\\"([0-9]+)\\.([0-9]+)\\.([0-9]+)\\\"$" "\\1.\\2.\\3" GDKPixbuf2_VERSION "${GDKPixbuf2_VERSION}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GDKPixbuf2
    REQUIRED_VARS GDKPixbuf2_LIBRARY
    VERSION_VAR GDKPixbuf2_VERSION)