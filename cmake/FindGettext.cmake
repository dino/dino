find_program(XGETTEXT_EXECUTABLE xgettext)
find_program(MSGMERGE_EXECUTABLE msgmerge)
find_program(MSGFMT_EXECUTABLE msgfmt)
find_program(MSGCAT_EXECUTABLE msgcat)

if(XGETTEXT_EXECUTABLE)
    execute_process(COMMAND ${XGETTEXT_EXECUTABLE} "--version"
                    OUTPUT_VARIABLE GETTEXT_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX REPLACE "xgettext \\(GNU gettext-tools\\) ([0-9\\.]*).*" "\\1" GETTEXT_VERSION "${GETTEXT_VERSION}")
endif(XGETTEXT_EXECUTABLE)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gettext
    REQUIRED_VARS XGETTEXT_EXECUTABLE MSGMERGE_EXECUTABLE MSGFMT_EXECUTABLE MSGCAT_EXECUTABLE
    VERSION_VAR GETTEXT_VERSION)

set(GETTEXT_USE_FILE "${CMAKE_CURRENT_LIST_DIR}/UseGettext.cmake")