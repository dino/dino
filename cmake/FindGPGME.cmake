set(GPGME_PKG_CONFIG_NAME gpgme)

find_program(GPGME_CONFIG_EXECUTABLE NAMES gpgme-config)
mark_as_advanced(GPGME_CONFIG_EXECUTABLE)

if(GPGME_CONFIG_EXECUTABLE)
    execute_process(COMMAND ${GPGME_CONFIG_EXECUTABLE} --version
                    OUTPUT_VARIABLE GPGME_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND ${GPGME_CONFIG_EXECUTABLE} --api-version
                    OUTPUT_VARIABLE GPGME_API_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND ${GPGME_CONFIG_EXECUTABLE} --cflags
                    OUTPUT_VARIABLE GPGME_CFLAGS
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    execute_process(COMMAND ${GPGME_CONFIG_EXECUTABLE} --libs
                    OUTPUT_VARIABLE GPGME_LDFLAGS
                    OUTPUT_STRIP_TRAILING_WHITESPACE)

    string(REGEX REPLACE "^(.* |)-l([^ ]*gpgme[^ ]*)( .*|)$" "\\2" GPGME_LIBRARY "${GPGME_LDFLAGS}")
    string(REGEX REPLACE "^(.* |)-L([^ ]*)( .*|)$" "\\2" GPGME_LIBRARY_DIRS "${GPGME_LDFLAGS}")
    find_library(LIB_NAME_GPGME ${GPGME_LIBRARY} HINTS ${GPGME_LIBRARY_DIRS})
    set(GPGME_LIBRARY ${LIB_NAME_GPGME})

    if(NOT TARGET gpgme)
        add_library(gpgme INTERFACE IMPORTED)
        set_property(TARGET gpgme PROPERTY INTERFACE_LINK_LIBRARIES "${GPGME_LDFLAGS}")
        set_property(TARGET gpgme PROPERTY INTERFACE_COMPILE_OPTIONS "${GPGME_CFLAGS}")
    endif(NOT TARGET gpgme)
endif(GPGME_CONFIG_EXECUTABLE)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GPGME
    REQUIRED_VARS GPGME_LIBRARY
    VERSION_VAR GPGME_VERSION)