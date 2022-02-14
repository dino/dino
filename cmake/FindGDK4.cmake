include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GDK4
    PKG_CONFIG_NAME gdk-4.0
    LIB_NAMES gdk-4
    INCLUDE_NAMES gdk/gdk.h
    INCLUDE_DIR_SUFFIXES gtk-4.0 gtk-4.0/include gtk+-4.0 gtk+-4.0/include
    DEPENDS Pango Cairo GDKPixbuf2
)

if(GDK4_FOUND AND NOT GDK4_VERSION)
    find_file(GDK4_VERSION_HEADER "gdk/gdkversionmacros.h" HINTS ${GDK4_INCLUDE_DIRS})
    mark_as_advanced(GDK4_VERSION_HEADER)

    if(GDK4_VERSION_HEADER)
        file(STRINGS "${GDK4_VERSION_HEADER}" GDK4_MAJOR_VERSION REGEX "^#define GDK_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK4_MAJOR_VERSION "${GDK4_MAJOR_VERSION}")
        file(STRINGS "${GDK4_VERSION_HEADER}" GDK4_MINOR_VERSION REGEX "^#define GDK_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK4_MINOR_VERSION "${GDK4_MINOR_VERSION}")
        file(STRINGS "${GDK4_VERSION_HEADER}" GDK4_MICRO_VERSION REGEX "^#define GDK_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GDK_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" GDK4_MICRO_VERSION "${GDK4_MICRO_VERSION}")
        set(GDK4_VERSION "${GDK4_MAJOR_VERSION}.${GDK4_MINOR_VERSION}.${GDK4_MICRO_VERSION}")
        unset(GDK4_MAJOR_VERSION)
        unset(GDK4_MINOR_VERSION)
        unset(GDK4_MICRO_VERSION)
    endif()
endif()

if (GDK4_FOUND)
    find_file(GDK4_WITH_X11 "gdk/gdkx.h" HINTS ${GDK4_INCLUDE_DIRS})
    if (GDK4_WITH_X11)
        set(GDK4_WITH_X11 yes CACHE INTERNAL "Does GDK4 support X11")
    endif (GDK4_WITH_X11)
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GDK4
    REQUIRED_VARS GDK4_LIBRARY
    VERSION_VAR GDK4_VERSION)