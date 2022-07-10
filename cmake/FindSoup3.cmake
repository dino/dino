include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Soup3
    PKG_CONFIG_NAME libsoup-3.0
    LIB_NAMES soup-3.0
    INCLUDE_NAMES libsoup/soup.h
    INCLUDE_DIR_SUFFIXES libsoup-2.4 libsoup-2.4/include libsoup libsoup/include
    DEPENDS GIO
)

if(Soup3_FOUND AND NOT Soup3_VERSION)
    find_file(Soup3_VERSION_HEADER "libsoup/soup-version.h" HINTS ${Soup3_INCLUDE_DIRS})
    mark_as_advanced(Soup3_VERSION_HEADER)

    if(Soup3_VERSION_HEADER)
        file(STRINGS "${Soup3_VERSION_HEADER}" Soup3_MAJOR_VERSION REGEX "^#define SOUP_MAJOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MAJOR_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup3_MAJOR_VERSION "${Soup3_MAJOR_VERSION}")
        file(STRINGS "${Soup3_VERSION_HEADER}" Soup3_MINOR_VERSION REGEX "^#define SOUP_MINOR_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MINOR_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup3_MINOR_VERSION "${Soup3_MINOR_VERSION}")
        file(STRINGS "${Soup3_VERSION_HEADER}" Soup3_MICRO_VERSION REGEX "^#define SOUP_MICRO_VERSION +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define SOUP_MICRO_VERSION \\(?([0-9]+)\\)?$" "\\1" Soup3_MICRO_VERSION "${Soup3_MICRO_VERSION}")
        set(Soup3_VERSION "${Soup3_MAJOR_VERSION}.${Soup3_MINOR_VERSION}.${Soup3_MICRO_VERSION}")
        unset(Soup3_MAJOR_VERSION)
        unset(Soup3_MINOR_VERSION)
        unset(Soup3_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Soup3
    REQUIRED_VARS Soup3_LIBRARY
    VERSION_VAR Soup3_VERSION)
