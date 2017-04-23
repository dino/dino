include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GLib
    PKG_CONFIG_NAME glib-2.0
    LIB_NAMES glib-2.0
    INCLUDE_NAMES glib.h glibconfig.h
    INCLUDE_DIR_HINTS ${CMAKE_LIBRARY_PATH} ${CMAKE_SYSTEM_LIBRARY_PATH}
    INCLUDE_DIR_PATHS ${CMAKE_PREFIX_PATH}/lib64 ${CMAKE_PREFIX_PATH}/lib
    INCLUDE_DIR_SUFFIXES glib-2.0 glib-2.0/include
)

if(GLib_FOUND AND NOT GLib_VERSION)
    find_file(GLib_CONFIG_HEADER "glibconfig.h" HINTS ${GLib_INCLUDE_DIRS})
    mark_as_advanced(GLib_CONFIG_HEADER)

    if(GLib_CONFIG_HEADER)
        file(STRINGS "${GLib_CONFIG_HEADER}" GLib_MAJOR_VERSION REGEX "^#define GLIB_MAJOR_VERSION +([0-9]+)")
        string(REGEX REPLACE "^#define GLIB_MAJOR_VERSION ([0-9]+)$" "\\1" GLib_MAJOR_VERSION "${GLib_MAJOR_VERSION}")
        file(STRINGS "${GLib_CONFIG_HEADER}" GLib_MINOR_VERSION REGEX "^#define GLIB_MINOR_VERSION +([0-9]+)")
        string(REGEX REPLACE "^#define GLIB_MINOR_VERSION ([0-9]+)$" "\\1" GLib_MINOR_VERSION "${GLib_MINOR_VERSION}")
        file(STRINGS "${GLib_CONFIG_HEADER}" GLib_MICRO_VERSION REGEX "^#define GLIB_MICRO_VERSION +([0-9]+)")
        string(REGEX REPLACE "^#define GLIB_MICRO_VERSION ([0-9]+)$" "\\1" GLib_MICRO_VERSION "${GLib_MICRO_VERSION}")
        set(GLib_VERSION "${GLib_MAJOR_VERSION}.${GLib_MINOR_VERSION}.${GLib_MICRO_VERSION}")
        unset(GLib_MAJOR_VERSION)
        unset(GLib_MINOR_VERSION)
        unset(GLib_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GLib
    REQUIRED_VARS GLib_LIBRARY
    VERSION_VAR GLib_VERSION)