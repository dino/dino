include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Pango
    PKG_CONFIG_NAME pango
    LIB_NAMES pango-1.0
    INCLUDE_NAMES pango/pango.h
    INCLUDE_DIR_SUFFIXES pango-1.0 pango-1.0/include
    DEPENDS GObject
)

if(Pango_FOUND AND NOT Pango_VERSION)
    find_path(Pango_INCLUDE_DIR "pango/pango.h" HINTS ${Pango_INCLUDE_DIRS})

    if(Pango_INCLUDE_DIR)
        file(STRINGS "${Pango_INCLUDE_DIR}/pango/pango-features.h" Pango_MAJOR_VERSION REGEX "^#define PANGO_VERSION_MAJOR +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define PANGO_VERSION_MAJOR \\(?([0-9]+)\\)?$" "\\1" Pango_MAJOR_VERSION "${Pango_MAJOR_VERSION}")
        file(STRINGS "${Pango_INCLUDE_DIR}/pango/pango-features.h" Pango_MINOR_VERSION REGEX "^#define PANGO_VERSION_MINOR +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define PANGO_VERSION_MINOR \\(?([0-9]+)\\)?$" "\\1" Pango_MINOR_VERSION "${Pango_MINOR_VERSION}")
        file(STRINGS "${Pango_INCLUDE_DIR}/pango/pango-features.h" Pango_MICRO_VERSION REGEX "^#define PANGO_VERSION_MICRO +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define PANGO_VERSION_MICRO \\(?([0-9]+)\\)?$" "\\1" Pango_MICRO_VERSION "${Pango_MICRO_VERSION}")
        set(Pango_VERSION "${Pango_MAJOR_VERSION}.${Pango_MINOR_VERSION}.${Pango_MICRO_VERSION}")
        unset(Pango_MAJOR_VERSION)
        unset(Pango_MINOR_VERSION)
        unset(Pango_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Pango
    FOUND_VAR Pango_FOUND
    REQUIRED_VARS Pango_LIBRARY
    VERSION_VAR Pango_VERSION
)