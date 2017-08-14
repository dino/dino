include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Soup
    PKG_CONFIG_NAME libsoup-2.4
    LIB_NAMES soup-2.4
    INCLUDE_NAMES libsoup/soup.h
    INCLUDE_DIR_SUFFIXES libsoup-2.4 libsoup-2.4/include libsoup libsoup/include
    DEPENDS GIO
)

if(Soup_FOUND AND NOT Soup_VERSION)
    find_file(Soup_VERSION_HEADER "libsoup/soup-version.h" HINTS ${Soup_INCLUDE_DIRS})
    mark_as_advanced(Soup_VERSION_HEADER)

    if(Soup_VERSION_HEADER)
        file(STRINGS "${Soup_VERSION_HEADER}" Soup_MAJOR_VERSION REGEX "^#define SOUP_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup_MAJOR_VERSION "${Soup_MAJOR_VERSION}")
        file(STRINGS "${Soup_VERSION_HEADER}" Soup_MINOR_VERSION REGEX "^#define SOUP_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup_MINOR_VERSION "${Soup_MINOR_VERSION}")
        file(STRINGS "${Soup_VERSION_HEADER}" Soup_MICRO_VERSION REGEX "^#define SOUP_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup_MICRO_VERSION "${Soup_MICRO_VERSION}")
        set(Soup_VERSION "${Soup_MAJOR_VERSION}.${Soup_MINOR_VERSION}.${Soup_MICRO_VERSION}")
        unset(Soup_MAJOR_VERSION)
        unset(Soup_MINOR_VERSION)
        unset(Soup_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Soup
    REQUIRED_VARS Soup_LIBRARY
    VERSION_VAR Soup_VERSION)
