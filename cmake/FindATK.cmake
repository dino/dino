include(PkgConfigWithFallback)
find_pkg_config_with_fallback(ATK
    PKG_CONFIG_NAME atk
    LIB_NAMES atk-1.0
    INCLUDE_NAMES atk/atk.h
    INCLUDE_DIR_SUFFIXES atk-1.0 atk-1.0/include
    DEPENDS GObject
)

if(ATK_FOUND AND NOT ATK_VERSION)
    find_path(ATK_INCLUDE_DIR "atk/atk.h" HINTS ${ATK_INCLUDE_DIRS})

    if(ATK_INCLUDE_DIR)
        file(STRINGS "${ATK_INCLUDE_DIR}/atk/atkversion.h" ATK_MAJOR_VERSION REGEX "^#define ATK_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define ATK_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" ATK_MAJOR_VERSION "${ATK_MAJOR_VERSION}")
        file(STRINGS "${ATK_INCLUDE_DIR}/atk/atkversion.h" ATK_MINOR_VERSION REGEX "^#define ATK_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define ATK_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" ATK_MINOR_VERSION "${ATK_MINOR_VERSION}")
        file(STRINGS "${ATK_INCLUDE_DIR}/atk/atkversion.h" ATK_MICRO_VERSION REGEX "^#define ATK_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define ATK_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" ATK_MICRO_VERSION "${ATK_MICRO_VERSION}")
        set(ATK_VERSION "${ATK_MAJOR_VERSION}.${ATK_MINOR_VERSION}.${ATK_MICRO_VERSION}")
        unset(ATK_MAJOR_VERSION)
        unset(ATK_MINOR_VERSION)
        unset(ATK_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ATK
    FOUND_VAR ATK_FOUND
    REQUIRED_VARS ATK_LIBRARY
    VERSION_VAR ATK_VERSION
)