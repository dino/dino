include(PkgConfigWithFallback)
find_pkg_config_with_fallback(ATK
    PKG_CONFIG_NAME atk
    LIB_NAMES atk-1.0
    INCLUDE_NAMES atk/atk.h
    INCLUDE_DIR_SUFFIXES atk-1.0 atk-1.0/include
    DEPENDS GObject
)

if(ATK_FOUND AND NOT ATK_VERSION)
    find_file(ATK_VERSION_HEADER "atk/atkversion.h" HINTS ${ATK_INCLUDE_DIRS})
    mark_as_advanced(ATK_VERSION_HEADER)

    if(ATK_VERSION_HEADER)
        file(STRINGS "${ATK_VERSION_HEADER}" ATK_MAJOR_VERSION REGEX "^#define ATK_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define ATK_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" ATK_MAJOR_VERSION "${ATK_MAJOR_VERSION}")
        file(STRINGS "${ATK_VERSION_HEADER}" ATK_MINOR_VERSION REGEX "^#define ATK_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define ATK_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" ATK_MINOR_VERSION "${ATK_MINOR_VERSION}")
        file(STRINGS "${ATK_VERSION_HEADER}" ATK_MICRO_VERSION REGEX "^#define ATK_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define ATK_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" ATK_MICRO_VERSION "${ATK_MICRO_VERSION}")
        set(ATK_VERSION "${ATK_MAJOR_VERSION}.${ATK_MINOR_VERSION}.${ATK_MICRO_VERSION}")
        unset(ATK_MAJOR_VERSION)
        unset(ATK_MINOR_VERSION)
        unset(ATK_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ATK
    REQUIRED_VARS ATK_LIBRARY
    VERSION_VAR ATK_VERSION)