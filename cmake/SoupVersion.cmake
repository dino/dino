find_package(Nice QUIET)
if (Nice_FOUND)
    file(GET_RUNTIME_DEPENDENCIES
        RESOLVED_DEPENDENCIES_VAR Nice_DEPENDENCIES
        UNRESOLVED_DEPENDENCIES_VAR Nice_UNRESOLVED_DEPENDENCIES
        LIBRARIES ${Nice_LIBRARY}
        PRE_INCLUDE_REGEXES "soup|gupnp"
        PRE_EXCLUDE_REGEXES "."
    )
    foreach (lib ${Nice_DEPENDENCIES})
        if (lib MATCHES ".*/libsoup-3.*")
            if(SOUP_VERSION AND NOT SOUP_VERSION EQUAL 3)
                message(FATAL_ERROR "libnice-${Nice_VERSION} depends on "
                    "libsoup-3, but SOUP_VERSION=${SOUP_VERSION} was given.")
            endif()

            set(SOUP_VERSION 3)
        endif ()
    endforeach ()
    foreach (lib ${Nice_DEPENDENCIES})
        if (lib MATCHES ".*/libsoup-2.*")
            if(SOUP_VERSION AND NOT SOUP_VERSION EQUAL 2)
                message(FATAL_ERROR "libnice-${Nice_VERSION} depends on "
                    "libsoup-2, but SOUP_VERSION=${SOUP_VERSION} was given.")
            endif()

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
    if (Soup3_FOUND AND NOT Soup2_FOUND)
        set(SOUP_VERSION 3)
    else ()
        set(SOUP_VERSION 2)
    endif ()
endif ()
set(Soup "Soup${SOUP_VERSION}")