include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GTK4
    PKG_CONFIG_NAME gtk4
    LIB_NAMES gtk-4
    INCLUDE_NAMES gtk/gtk.h
    INCLUDE_DIR_SUFFIXES gtk-4.0 gtk-4.0/include gtk+-4.0 gtk+-4.0/include gtk4 gtk4/include
)

if(GTK4_FOUND AND NOT GTK4_VERSION)
    find_file(GTK4_VERSION_HEADER "gtk/gtkversion.h" HINTS ${GTK4_INCLUDE_DIRS})
    mark_as_advanced(GTK4_VERSION_HEADER)

    if(GTK4_VERSION_HEADER)
        file(STRINGS "${GTK4_VERSION_HEADER}" GTK4_MAJOR_VERSION REGEX "^#define GTK_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GTK_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GTK4_MAJOR_VERSION "${GTK4_MAJOR_VERSION}")
        file(STRINGS "${GTK4_VERSION_HEADER}" GTK4_MINOR_VERSION REGEX "^#define GTK_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GTK_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" GTK4_MINOR_VERSION "${GTK4_MINOR_VERSION}")
        file(STRINGS "${GTK4_VERSION_HEADER}" GTK4_MICRO_VERSION REGEX "^#define GTK_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define GTK_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" GTK4_MICRO_VERSION "${GTK4_MICRO_VERSION}")
        set(GTK4_VERSION "${GTK4_MAJOR_VERSION}.${GTK4_MINOR_VERSION}.${GTK4_MICRO_VERSION}")
        unset(GTK4_MAJOR_VERSION)
        unset(GTK4_MINOR_VERSION)
        unset(GTK4_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GTK4
    REQUIRED_VARS GTK4_LIBRARY
    VERSION_VAR GTK4_VERSION)
