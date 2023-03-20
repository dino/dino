dependencies = [
    dep_gee,
    dep_glib,
    dep_sqlite3,
]
sources = files(
    'src/column.vala',
    'src/database.vala',
    'src/delete_builder.vala',
    'src/insert_builder.vala',
    'src/query_builder.vala',
    'src/row.vala',
    'src/statement_builder.vala',
    'src/table.vala',
    'src/update_builder.vala',
    'src/upsert_builder.vala',
)
c_args = [
    '-DG_LOG_DOMAIN="qlite"',
]
lib_qlite = library('qlite', sources, c_args: c_args, vala_args: ['--vapidir', meson.current_source_dir() / 'vapi'], dependencies: dependencies)
dep_qlite = declare_dependency(link_with: lib_qlite, include_directories: include_directories('.'))
