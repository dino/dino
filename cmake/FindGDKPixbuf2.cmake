include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GDKPixbuf2
    PKG_CONFIG_NAME gdk-pixbuf-2.0
    LIB_NAMES gdk_pixbuf-2.0
    INCLUDE_NAMES gdk-pixbuf/gdk-pixbuf.h
    INCLUDE_DIR_SUFFIXES gdk-pixbuf-2.0 gdk-pixbuf-2.0/include
    DEPENDS GLib
)

if(GDKPixbuf2_FOUND AND NOT GDKPixbuf2_VERSION)
    find_path(GDKPixbuf2_INCLUDE_DIR "gdk-pixbuf/gdk-pixbuf.h" HINTS ${GDKPixbuf2_INCLUDE_DIRS})

    if(GDKPixbuf2_INCLUDE_DIR)
        file(STRINGS "${GDKPixbuf2_INCLUDE_DIR}/gdk-pixbuf/gdk-pixbuf-features.h" GDKPixbuf2_VERSION REGEX "^#define GDK_PIXBUF_VERSION \\\"[^\\\"]+\\\"")
        string(REGEX REPLACE "^#define GDK_PIXBUF_VERSION \\\"([0-9]+)\\.([0-9]+)\\.([0-9]+)\\\"$" "\\1.\\2.\\3" GDKPixbuf2_VERSION "${GDKPixbuf2_VERSION}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GDKPixbuf2
    FOUND_VAR GDKPixbuf2_FOUND
    REQUIRED_VARS GDKPixbuf2_LIBRARY
    VERSION_VAR GDKPixbuf2_VERSION
)