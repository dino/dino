include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GDK3
    PKG_CONFIG_NAME gdk-3.0
    LIB_NAMES gdk-3
    INCLUDE_NAMES gdk/gdk.h
    INCLUDE_DIR_SUFFIXES gtk-3.0 gtk-3.0/include gtk+-3.0 gtk+-3.0/include
    DEPENDS Pango Cairo GDKPixbuf2
)

if(GDK3_FOUND AND NOT GDK3_VERSION)
    find_file(GDK3_VERSION_HEADER "gdk/gdkversionmacros.h" HINTS ${GDK3_INCLUDE_DIRS})
    mark_as_advanced(GDK3_VERSION_HEADER)

    if(GDK3_VERSION_HEADER)
        file(STRINGS "${GDK3_VERSION_HEADER}" GDK3_MAJOR_VERSION REGEX "^#define GDK_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK3_MAJOR_VERSION "${GDK3_MAJOR_VERSION}")
        file(STRINGS "${GDK3_VERSION_HEADER}" GDK3_MINOR_VERSION REGEX "^#define GDK_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK3_MINOR_VERSION "${GDK3_MINOR_VERSION}")
        file(STRINGS "${GDK3_VERSION_HEADER}" GDK3_MICRO_VERSION REGEX "^#define GDK_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK3_MICRO_VERSION "${GDK3_MICRO_VERSION}")
        set(GDK3_VERSION "${GDK3_MAJOR_VERSION}.${GDK3_MINOR_VERSION}.${GDK3_MICRO_VERSION}")
        unset(GDK3_MAJOR_VERSION)
        unset(GDK3_MINOR_VERSION)
        unset(GDK3_MICRO_VERSION)
    endif()
endif()

if(GDK3_FOUND)
    find_file(GDK3_WITH_X11 "gdk/gdkx.h" HINTS ${GDK3_INCLUDE_DIRS})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GDK3
    REQUIRED_VARS GDK3_LIBRARY
    VERSION_VAR GDK3_VERSION)