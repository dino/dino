# TODO: Windows related stuff

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
                    OUTPUT_VARIABLE GPGME_LIBRARIES
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif(GPGME_CONFIG_EXECUTABLE)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GPGME
    REQUIRED_VARS GPGME_CONFIG_EXECUTABLE
    VERSION_VAR GPGME_VERSION)