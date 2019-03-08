find_package(GPGME REQUIRED)
find_packages(GPGME_VALA_PACKAGES REQUIRED
    Gee
    GLib
    GObject
)

vala_precompile(GPGME_VALA_C
SOURCES
    "src/gpgme_helper.vala"
CUSTOM_VAPIS
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/gpgme.vapi"
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/gpgme_public.vapi"
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/gpg-error.vapi"
PACKAGES
    ${GPGME_VALA_PACKAGES}
GENERATE_VAPI
    gpgme-vala
GENERATE_HEADER
    gpgme-vala
)

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/gpgme_fix.h"
COMMAND
    cp "${CMAKE_CURRENT_SOURCE_DIR}/src/gpgme_fix.h" "${CMAKE_BINARY_DIR}/exports/gpgme_fix.h"
DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/gpgme_fix.h"
COMMENT
    Copy header file gpgme_fix.h
)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/exports/gpgme.vapi
COMMAND
    cat "${CMAKE_BINARY_DIR}/exports/gpgme-vala.vapi" "${CMAKE_CURRENT_SOURCE_DIR}/vapi/gpgme_public.vapi" > "${CMAKE_BINARY_DIR}/exports/gpgme.vapi"
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/gpgme-vala.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/gpgme_public.vapi
)

add_custom_target(gpgme-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/gpgme_fix.h
    ${CMAKE_BINARY_DIR}/exports/gpgme.vapi
)

set(CFLAGS ${VALA_CFLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_definitions(${CFLAGS})
add_library(gpgme-vala ${GPGME_VALA_C} src/gpgme_fix.c)
add_dependencies(gpgme-vala gpgme-vapi)
target_link_libraries(gpgme-vala ${GPGME_VALA_PACKAGES} gpgme gpg-error)
set_property(TARGET gpgme-vala PROPERTY POSITION_INDEPENDENT_CODE ON)

