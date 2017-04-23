find_program(XGETTEXT_EXECUTABLE xgettext)
find_program(MSGMERGE_EXECUTABLE msgmerge)
find_program(MSGFMT_EXECUTABLE msgfmt)
find_program(MSGCAT_EXECUTABLE msgcat)
mark_as_advanced(XGETTEXT_EXECUTABLE MSGMERGE_EXECUTABLE MSGFMT_EXECUTABLE MSGCAT_EXECUTABLE)

if(XGETTEXT_EXECUTABLE)
    execute_process(COMMAND ${XGETTEXT_EXECUTABLE} "--version"
                    OUTPUT_VARIABLE Gettext_VERSION
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX REPLACE "xgettext \\(GNU gettext-tools\\) ([0-9\\.]*).*" "\\1" Gettext_VERSION "${Gettext_VERSION}")
endif(XGETTEXT_EXECUTABLE)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gettext
    FOUND_VAR Gettext_FOUND
    REQUIRED_VARS XGETTEXT_EXECUTABLE MSGMERGE_EXECUTABLE MSGFMT_EXECUTABLE MSGCAT_EXECUTABLE
    VERSION_VAR Gettext_VERSION)

set(GETTEXT_USE_FILE "${CMAKE_CURRENT_LIST_DIR}/UseGettext.cmake")