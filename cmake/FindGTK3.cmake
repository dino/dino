include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GTK3
    PKG_CONFIG_NAME gtk+-3.0
    LIB_NAMES gtk-3
    INCLUDE_NAMES gtk/gtk.h
    INCLUDE_DIR_SUFFIXES gtk-3.0 gtk-3.0/include gtk+-3.0 gtk+-3.0/include
    DEPENDS GDK3 ATK
)

if(GTK3_FOUND AND NOT GTK3_VERSION)
    find_path(GTK3_INCLUDE_DIR "gtk/gtk.h" HINTS ${GTK3_INCLUDE_DIRS})

    if(GTK3_INCLUDE_DIR)
        file(STRINGS "${GTK3_INCLUDE_DIR}/gtk/gtkversion.h" GTK3_MAJOR_VERSION REGEX "^#define GTK_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GTK_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GTK3_MAJOR_VERSION "${GTK3_MAJOR_VERSION}")
        file(STRINGS "${GTK3_INCLUDE_DIR}/gtk/gtkversion.h" GTK3_MINOR_VERSION REGEX "^#define GTK_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GTK_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GTK3_MINOR_VERSION "${GTK3_MINOR_VERSION}")
        file(STRINGS "${GTK3_INCLUDE_DIR}/gtk/gtkversion.h" GTK3_MICRO_VERSION REGEX "^#define GTK_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GTK_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" GTK3_MICRO_VERSION "${GTK3_MICRO_VERSION}")
        set(GTK3_VERSION "${GTK3_MAJOR_VERSION}.${GTK3_MINOR_VERSION}.${GTK3_MICRO_VERSION}")
        unset(GTK3_MAJOR_VERSION)
        unset(GTK3_MINOR_VERSION)
        unset(GTK3_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GTK3
    FOUND_VAR GTK3_FOUND
    REQUIRED_VARS GTK3_LIBRARY
    VERSION_VAR GTK3_VERSION
)