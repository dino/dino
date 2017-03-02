find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
include(${VALA_USE_FILE})

set(QLITE_PACKAGES
    gee-0.8
    glib-2.0
    sqlite3
)

pkg_check_modules(QLITE REQUIRED ${QLITE_PACKAGES})

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
OPTIONS
    -g
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

set(CFLAGS ${QLITE_CFLAGS} -g ${VALA_CFLAGS})
add_definitions(${CFLAGS})
add_library(qlite SHARED ${QLITE_VALA_C})
target_link_libraries(qlite ${QLITE_LIBRARIES})

add_custom_target(qlite-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/qlite/qlite.vapi
)

