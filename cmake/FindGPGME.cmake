set(GPGME_PKG_CONFIG_NAME gpgme)

find_program(GPGME_CONFIG_EXECUTABLE NAMES gpgme-config)
mark_as_advanced(GPGME_CONFIG_EXECUTABLE)
find_program(GPGME_SH_EXECUTABLE NAMES sh)
mark_as_advanced(GPGME_SH_EXECUTABLE)


if(GPGME_CONFIG_EXECUTABLE)
    macro(gpgme_config_fail errcode)
        if(${errcode})
            message(FATAL_ERROR "Error invoking gpgme-config: ${errcode}")
        endif(${errcode})
    endmacro(gpgme_config_fail)
    file(TO_NATIVE_PATH "${GPGME_CONFIG_EXECUTABLE}" GPGME_CONFIG_EXECUTABLE)
    file(TO_NATIVE_PATH "${GPGME_SH_EXECUTABLE}" GPGME_SH_EXECUTABLE)

    execute_process(COMMAND "${GPGME_SH_EXECUTABLE}" "${GPGME_CONFIG_EXECUTABLE}" --version
                    OUTPUT_VARIABLE GPGME_VERSION
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gpgme_config_fail(${ERRCODE})

    execute_process(COMMAND "${GPGME_SH_EXECUTABLE}" "${GPGME_CONFIG_EXECUTABLE}" --api-version
                    OUTPUT_VARIABLE GPGME_API_VERSION
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gpgme_config_fail(${ERRCODE})

    execute_process(COMMAND "${GPGME_SH_EXECUTABLE}" "${GPGME_CONFIG_EXECUTABLE}" --cflags
                    OUTPUT_VARIABLE GPGME_CFLAGS
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gpgme_config_fail(${ERRCODE})

    execute_process(COMMAND "${GPGME_SH_EXECUTABLE}" "${GPGME_CONFIG_EXECUTABLE}" --libs
                    OUTPUT_VARIABLE GPGME_LDFLAGS
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gpgme_config_fail(${ERRCODE})

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