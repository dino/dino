include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Cairo
    PKG_CONFIG_NAME cairo
    LIB_NAMES cairo
    INCLUDE_NAMES cairo.h
    INCLUDE_DIR_SUFFIXES cairo cairo/include
)

if(Cairo_FOUND AND NOT Cairo_VERSION)
    find_path(Cairo_INCLUDE_DIR "cairo.h" HINTS ${Cairo_INCLUDE_DIRS})

    if(Cairo_INCLUDE_DIR)
        file(STRINGS "${Cairo_INCLUDE_DIR}/cairo-version.h" Cairo_MAJOR_VERSION REGEX "^#define CAIRO_VERSION_MAJOR +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define CAIRO_VERSION_MAJOR \\(?([0-9]+)\\)?$" "\\1" Cairo_MAJOR_VERSION "${Cairo_MAJOR_VERSION}")
        file(STRINGS "${Cairo_INCLUDE_DIR}/cairo-version.h" Cairo_MINOR_VERSION REGEX "^#define CAIRO_VERSION_MINOR +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define CAIRO_VERSION_MINOR \\(?([0-9]+)\\)?$" "\\1" Cairo_MINOR_VERSION "${Cairo_MINOR_VERSION}")
        file(STRINGS "${Cairo_INCLUDE_DIR}/cairo-version.h" Cairo_MICRO_VERSION REGEX "^#define CAIRO_VERSION_MICRO +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define CAIRO_VERSION_MICRO \\(?([0-9]+)\\)?$" "\\1" Cairo_MICRO_VERSION "${Cairo_MICRO_VERSION}")
        set(Cairo_VERSION "${Cairo_MAJOR_VERSION}.${Cairo_MINOR_VERSION}.${Cairo_MICRO_VERSION}")
        unset(Cairo_MAJOR_VERSION)
        unset(Cairo_MINOR_VERSION)
        unset(Cairo_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Cairo
    FOUND_VAR Cairo_FOUND
    REQUIRED_VARS Cairo_LIBRARY
    VERSION_VAR Cairo_VERSION
)