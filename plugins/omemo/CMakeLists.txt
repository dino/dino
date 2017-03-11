find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
include(${VALA_USE_FILE})

set(OMEMO_PACKAGES
    gee-0.8
    gio-2.0
    glib-2.0
    gtk+-3.0
    gmodule-2.0
    sqlite3
)

pkg_check_modules(OMEMO REQUIRED ${OMEMO_PACKAGES})

vala_precompile(OMEMO_VALA_C
SOURCES
    src/plugin.vala
    src/module.vala
    src/manager.vala
    src/database.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/signal-protocol.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
PACKAGES
    ${OMEMO_PACKAGES}
OPTIONS
    --target-glib=2.38
    ${GLOBAL_DEBUG_FLAGS}
    --thread
)

set(CFLAGS ${VALA_CFLAGS} ${OMEMO_CFLAGS})
add_definitions(${CFLAGS})
add_library(omemo SHARED ${OMEMO_VALA_C})
add_dependencies(omemo dino-vapi signal-protocol-vapi)
target_link_libraries(omemo libdino signal-protocol-vala)
set_target_properties(omemo PROPERTIES PREFIX "")
set_target_properties(omemo PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)
