set(GCrypt_PKG_CONFIG_NAME gcrypt)

find_program(GCrypt_CONFIG_EXECUTABLE NAMES libgcrypt-config)
mark_as_advanced(GCrypt_CONFIG_EXECUTABLE)
find_program(GCrypt_SH_EXECUTABLE NAMES sh)
mark_as_advanced(GCrypt_SH_EXECUTABLE)


if(GCrypt_CONFIG_EXECUTABLE)
    macro(gcrypt_config_fail errcode)
        if(${errcode})
            message(FATAL_ERROR "Error invoking libgcrypt-config: ${errcode}")
        endif(${errcode})
    endmacro(gcrypt_config_fail)
    file(TO_NATIVE_PATH "${GCrypt_CONFIG_EXECUTABLE}" GCrypt_CONFIG_EXECUTABLE)
    file(TO_NATIVE_PATH "${GCrypt_SH_EXECUTABLE}" GCrypt_SH_EXECUTABLE)

    execute_process(COMMAND "${GCrypt_SH_EXECUTABLE}" "${GCrypt_CONFIG_EXECUTABLE}" --version
                    OUTPUT_VARIABLE GCrypt_VERSION
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gcrypt_config_fail(${ERRCODE})

    execute_process(COMMAND "${GCrypt_SH_EXECUTABLE}" "${GCrypt_CONFIG_EXECUTABLE}" --api-version
                    OUTPUT_VARIABLE GCrypt_API_VERSION
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gcrypt_config_fail(${ERRCODE})

    execute_process(COMMAND "${GCrypt_SH_EXECUTABLE}" "${GCrypt_CONFIG_EXECUTABLE}" --cflags
                    OUTPUT_VARIABLE GCrypt_CFLAGS
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gcrypt_config_fail(${ERRCODE})

    execute_process(COMMAND "${GCrypt_SH_EXECUTABLE}" "${GCrypt_CONFIG_EXECUTABLE}" --libs
                    OUTPUT_VARIABLE GCrypt_LDFLAGS
                    RESULT_VARIABLE ERRCODE
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    gcrypt_config_fail(${ERRCODE})

    string(REGEX REPLACE "^(.* |)-l([^ ]*gcrypt[^ ]*)( .*|)$" "\\2" GCrypt_LIBRARY_NAME "${GCrypt_LDFLAGS}")
    string(REGEX REPLACE "^(.* |)-L([^ ]*)( .*|)$" "\\2" GCrypt_LIBRARY_DIRS "${GCrypt_LDFLAGS}")
    find_library(GCrypt_LIBRARY ${GCrypt_LIBRARY_NAME} HINTS ${GCrypt_LIBRARY_DIRS})
    mark_as_advanced(GCrypt_LIBRARY)
    unset(GCrypt_LIBRARY_NAME)
    unset(GCrypt_LIBRARY_DIRS)

    if(NOT TARGET gcrypt)
        add_library(gcrypt INTERFACE IMPORTED)
        set_property(TARGET gcrypt PROPERTY INTERFACE_LINK_LIBRARIES "${GCrypt_LDFLAGS}")
        set_property(TARGET gcrypt PROPERTY INTERFACE_COMPILE_OPTIONS "${GCrypt_CFLAGS}")
    endif(NOT TARGET gcrypt)
endif(GCrypt_CONFIG_EXECUTABLE)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GCrypt
    REQUIRED_VARS GCrypt_LIBRARY
    VERSION_VAR GCrypt_VERSION)
