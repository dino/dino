include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GDK3
    PKG_CONFIG_NAME gdk-3.0
    LIB_NAMES gdk-3
    INCLUDE_NAMES gdk/gdk.h
    INCLUDE_DIR_SUFFIXES gtk-3.0 gtk-3.0/include gtk+-3.0 gtk+-3.0/include
    DEPENDS Pango Cairo GDKPixbuf2
)

if(GDK3_FOUND AND NOT GDK3_VERSION)
    find_path(GDK3_INCLUDE_DIR "gdk/gdk.h" HINTS ${GDK3_INCLUDE_DIRS})

    if(GDK3_INCLUDE_DIR)
        file(STRINGS "${GDK3_INCLUDE_DIR}/gdk/gdkversionmacros.h" GDK3_MAJOR_VERSION REGEX "^#define GDK_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK3_MAJOR_VERSION "${GDK3_MAJOR_VERSION}")
        file(STRINGS "${GDK3_INCLUDE_DIR}/gdk/gdkversionmacros.h" GDK3_MINOR_VERSION REGEX "^#define GDK_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK3_MINOR_VERSION "${GDK3_MINOR_VERSION}")
        file(STRINGS "${GDK3_INCLUDE_DIR}/gdk/gdkversionmacros.h" GDK3_MICRO_VERSION REGEX "^#define GDK_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK3_MICRO_VERSION "${GDK3_MICRO_VERSION}")
        set(GDK3_VERSION "${GDK3_MAJOR_VERSION}.${GDK3_MINOR_VERSION}.${GDK3_MICRO_VERSION}")
        unset(GDK3_MAJOR_VERSION)
        unset(GDK3_MINOR_VERSION)
        unset(GDK3_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GDK3
    FOUND_VAR GDK3_FOUND
    REQUIRED_VARS GDK3_LIBRARY
    VERSION_VAR GDK3_VERSION
)