find_packages(QLITE_PACKAGES REQUIRED
    Gee
    GLib
    GObject
    SQLite3
)

vala_precompile(QLITE_VALA_C
SOURCES
    "src/database.vala"
    "src/table.vala"
    "src/column.vala"
    "src/row.vala"

    "src/statement_builder.vala"
    "src/query_builder.vala"
    "src/insert_builder.vala"
    "src/update_builder.vala"
    "src/delete_builder.vala"
PACKAGES
    ${QLITE_PACKAGES}
GENERATE_VAPI
    qlite
GENERATE_HEADER
    qlite
)

add_definitions(${VALA_CFLAGS})
add_library(qlite SHARED ${QLITE_VALA_C})
target_link_libraries(qlite ${QLITE_PACKAGES})

add_custom_target(qlite-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.deps
)

install(TARGETS qlite ${TARGET_INSTALL})
install(FILES ${CMAKE_BINARY_DIR}/exports/qlite.vapi ${CMAKE_BINARY_DIR}/exports/qlite.deps DESTINATION ${VAPI_INSTALL_DIR})
install(FILES ${CMAKE_BINARY_DIR}/exports/qlite.h DESTINATION ${INCLUDE_INSTALL_DIR})
