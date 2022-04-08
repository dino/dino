include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Soup2
    PKG_CONFIG_NAME libsoup-2.4
    LIB_NAMES soup-2.4
    INCLUDE_NAMES libsoup/soup.h
    INCLUDE_DIR_SUFFIXES libsoup-2.4 libsoup-2.4/include libsoup libsoup/include
    DEPENDS GIO
)

if(Soup2_FOUND AND NOT Soup2_VERSION)
    find_file(Soup2_VERSION_HEADER "libsoup/soup-version.h" HINTS ${Soup_INCLUDE_DIRS})
    mark_as_advanced(Soup2_VERSION_HEADER)

    if(Soup_VERSION_HEADER)
        file(STRINGS "${Soup2_VERSION_HEADER}" Soup2_MAJOR_VERSION REGEX "^#define SOUP_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup_MAJOR_VERSION "${Soup2_MAJOR_VERSION}")
        file(STRINGS "${Soup2_VERSION_HEADER}" Soup2_MINOR_VERSION REGEX "^#define SOUP_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup_MINOR_VERSION "${Soup2_MINOR_VERSION}")
        file(STRINGS "${Soup2_VERSION_HEADER}" Soup2_MICRO_VERSION REGEX "^#define SOUP_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup_MICRO_VERSION "${Soup2_MICRO_VERSION}")
        set(Soup_VERSION "${Soup2_MAJOR_VERSION}.${Soup2_MINOR_VERSION}.${Soup2_MICRO_VERSION}")
        unset(Soup2_MAJOR_VERSION)
        unset(Soup2_MINOR_VERSION)
        unset(Soup2_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Soup2
    REQUIRED_VARS Soup2_LIBRARY
    VERSION_VAR Soup2_VERSION)
