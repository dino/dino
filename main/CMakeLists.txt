find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
include(${VALA_USE_FILE})

set(MAIN_PACKAGES
    gee-0.8
    gio-2.0
    glib-2.0
    gtk+-3.0
    gmodule-2.0
    sqlite3
)

pkg_check_modules(MAIN REQUIRED ${MAIN_PACKAGES})

vala_precompile(MAIN_VALA_C
SOURCES
    src/main.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/xmpp-vala/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/qlite/qlite.vapi
    ${CMAKE_BINARY_DIR}/libdino/dino.vapi
PACKAGES
    ${MAIN_PACKAGES}
OPTIONS
    --target-glib=2.38
    -g
    --thread
)

set(CFLAGS ${VALA_CFLAGS} ${MAIN_CFLAGS} -I${CMAKE_BINARY_DIR}/xmpp-vala -I${CMAKE_BINARY_DIR}/qlite -I${CMAKE_BINARY_DIR}/libdino)
add_definitions(${CFLAGS})
add_executable(dino ${MAIN_VALA_C})
add_dependencies(dino dino-vapi)
target_link_libraries(dino libdino)