find_package(Nice QUIET)
if (Nice_FOUND AND NOT SOUP_VERSION AND NOT USE_SOUP3)
    file(GET_RUNTIME_DEPENDENCIES
        RESOLVED_DEPENDENCIES_VAR Nice_DEPENDENCIES
        UNRESOLVED_DEPENDENCIES_VAR Nice_UNRESOLVED_DEPENDENCIES
        LIBRARIES ${Nice_LIBRARY}
        PRE_INCLUDE_REGEXES "soup|gupnp"
        PRE_EXCLUDE_REGEXES "."
    )
    foreach (lib ${Nice_DEPENDENCIES})
        if (lib MATCHES ".*/libsoup-3.*")
            set(SOUP_VERSION 3)
        endif ()
    endforeach ()
    foreach (lib ${Nice_DEPENDENCIES})
        if (lib MATCHES ".*/libsoup-2.*")
            set(SOUP_VERSION 2)
        endif ()
    endforeach ()
    set(SOUP_VERSION ${SOUP_VERSION} CACHE STRING "Version of libsoup to use")
    set_property(CACHE SOUP_VERSION PROPERTY STRINGS "2" "3")
    message(STATUS "Using Soup${SOUP_VERSION} to provide Soup")
elseif (NOT SOUP_VERSION)
    find_package(Soup2 QUIET)
    find_package(Soup3 QUIET)
    # Only use libsoup 3 if specifically requested or when libsoup 2 is not available
    if (Soup3_FOUND AND NOT Soup2_FOUND OR USE_SOUP3)
        set(SOUP_VERSION 3)
    else ()
        set(SOUP_VERSION 2)
    endif ()
endif ()
set(Soup "Soup${SOUP_VERSION}")