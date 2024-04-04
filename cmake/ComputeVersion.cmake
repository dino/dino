include(CMakeParseArguments)

function(_compute_version_from_file)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/VERSION)
    if (NOT EXISTS ${CMAKE_SOURCE_DIR}/VERSION)
        set(VERSION_FOUND 0 PARENT_SCOPE)
        return()
    endif ()
    file(STRINGS ${CMAKE_SOURCE_DIR}/VERSION VERSION_FILE)
    string(REPLACE " " ";" VERSION_FILE "${VERSION_FILE}")
    cmake_parse_arguments(VERSION_FILE "" "RELEASE;PRERELEASE" "" ${VERSION_FILE})
    if (DEFINED VERSION_FILE_RELEASE)
        string(STRIP "${VERSION_FILE_RELEASE}" VERSION_FILE_RELEASE)
        set(VERSION_IS_RELEASE 1 PARENT_SCOPE)
        set(VERSION_FULL "${VERSION_FILE_RELEASE}" PARENT_SCOPE)
        set(VERSION_FOUND 1 PARENT_SCOPE)
    elseif (DEFINED VERSION_FILE_PRERELEASE)
        string(STRIP "${VERSION_FILE_PRERELEASE}" VERSION_FILE_PRERELEASE)
        set(VERSION_IS_RELEASE 0 PARENT_SCOPE)
        set(VERSION_FULL "${VERSION_FILE_PRERELEASE}" PARENT_SCOPE)
        set(VERSION_FOUND 1 PARENT_SCOPE)
    else ()
        set(VERSION_FOUND 0 PARENT_SCOPE)
    endif ()
endfunction(_compute_version_from_file)

function(_compute_version_from_git)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/.git)
    if (NOT GIT_EXECUTABLE)
        find_package(Git QUIET)
        if (NOT GIT_FOUND)
            return()
        endif ()
    endif (NOT GIT_EXECUTABLE)

    # Git tag
    execute_process(
            COMMAND "${GIT_EXECUTABLE}" describe --tags --abbrev=0
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            RESULT_VARIABLE git_result
            OUTPUT_VARIABLE git_tag
            ERROR_VARIABLE git_error
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
    )
    if (NOT git_result EQUAL 0)
        return()
    endif (NOT git_result EQUAL 0)

    if (git_tag MATCHES "^v?([0-9]+[.]?[0-9]*[.]?[0-9]*[.]?[0-9]*)(-[.0-9A-Za-z-]+)?([+][.0-9A-Za-z-]+)?$")
        set(VERSION_LAST_RELEASE "${CMAKE_MATCH_1}")
    else ()
        return()
    endif ()

    # Git describe
    execute_process(
            COMMAND "${GIT_EXECUTABLE}" describe --tags
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            RESULT_VARIABLE git_result
            OUTPUT_VARIABLE git_describe
            ERROR_VARIABLE git_error
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
    )
    if (NOT git_result EQUAL 0)
        return()
    endif (NOT git_result EQUAL 0)

    if ("${git_tag}" STREQUAL "${git_describe}")
        set(VERSION_IS_RELEASE 1)
    else ()
        set(VERSION_IS_RELEASE 0)
        if (git_describe MATCHES "-([0-9]+)-g([0-9a-f]+)$")
            set(VERSION_TAG_OFFSET "${CMAKE_MATCH_1}")
            set(VERSION_COMMIT_HASH "${CMAKE_MATCH_2}")
        endif ()
        execute_process(
                COMMAND "${GIT_EXECUTABLE}" show --format=%cd --date=format:%Y%m%d -s
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                RESULT_VARIABLE git_result
                OUTPUT_VARIABLE git_time
                ERROR_VARIABLE git_error
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_STRIP_TRAILING_WHITESPACE
        )
        if (NOT git_result EQUAL 0)
            return()
        endif (NOT git_result EQUAL 0)
        set(VERSION_COMMIT_DATE "${git_time}")
    endif ()
    if (NOT VERSION_IS_RELEASE)
        set(VERSION_SUFFIX "~git${VERSION_TAG_OFFSET}.${VERSION_COMMIT_DATE}.${VERSION_COMMIT_HASH}")
    else (NOT VERSION_IS_RELEASE)
        set(VERSION_SUFFIX "")
    endif (NOT VERSION_IS_RELEASE)
    set(VERSION_IS_RELEASE ${VERSION_IS_RELEASE} PARENT_SCOPE)
    set(VERSION_FULL "${VERSION_LAST_RELEASE}${VERSION_SUFFIX}" PARENT_SCOPE)
    set(VERSION_FOUND 1 PARENT_SCOPE)
endfunction(_compute_version_from_git)

_compute_version_from_file()
if (NOT VERSION_FOUND)
    _compute_version_from_git()
endif (NOT VERSION_FOUND)