using Sqlite;

namespace Qlite {

public class Database {
    private string file_name;
    private Sqlite.Database db;
    private long expected_version;
    private Table[]? tables;

    private Column<string?> meta_name = new Column.Text("name") { primary_key = true };
    private Column<long> meta_int_val = new Column.Long("int_val");
    private Column<string?> meta_text_val = new Column.Text("text_val");
    private Table meta_table;

    public bool debug = false;

    public Database(string file_name, long expected_version) {
        this.file_name = file_name;
        this.expected_version = expected_version;
        meta_table = new Table(this, "_meta");
        meta_table.init({meta_name, meta_int_val, meta_text_val});
    }

    public void init(Table[] tables) {
        Sqlite.config(Config.SERIALIZED);
        int ec = Sqlite.Database.open_v2(file_name, out db, OPEN_READWRITE | OPEN_CREATE | 0x00010000);
        if (ec != Sqlite.OK) {
            error(@"SQLite error: %d - %s", db.errcode(), db.errmsg());
        }
        this.tables = tables;
        if (debug) db.trace((message) => print(@"Qlite trace: $message\n"));
        start_migration();
    }

    public void ensure_init() {
        if (tables == null) error(@"Database $file_name was not initialized, call init()");
    }

    private void start_migration() {
        try {
            exec("BEGIN TRANSACTION");
        } catch (Error e) {
            error("SQLite error: %d - %s", db.errcode(), db.errmsg());
        }
        meta_table.create_table_at_version(expected_version);
        long old_version = 0;
        old_version = meta_table.row_with(meta_name, "version")[meta_int_val, -1];
        if (old_version == -1) {
            foreach (Table t in tables) {
                t.create_table_at_version(expected_version);
            }
            meta_table.insert().value(meta_name, "version").value(meta_int_val, expected_version).perform();
        } else if (expected_version != old_version) {
            foreach (Table t in tables) {
                t.create_table_at_version(old_version);
            }
            foreach (Table t in tables) {
                t.add_columns_for_version(old_version, expected_version);
            }
            migrate(old_version);
            foreach (Table t in tables) {
                t.delete_columns_for_version(old_version, expected_version);
            }
            if (old_version == -1) {
                meta_table.insert().value(meta_name, "version").value(meta_int_val, expected_version).perform();
            } else {
                meta_table.update().with(meta_name, "=", "version").set(meta_int_val, expected_version).perform();
            }
        }
        foreach (Table t in tables) {
            t.post();
        }
        try {
            exec("END TRANSACTION");
        } catch (Error e) {
            error("SQLite error: %d - %s", db.errcode(), db.errmsg());
        }
    }

    internal int errcode() {
        return db.errcode();
    }

    internal string errmsg() {
        return db.errmsg();
    }

    internal int64 last_insert_rowid() {
        return db.last_insert_rowid();
    }

    // To be implemented by actual implementation if required
    // new table columns are added, outdated columns are still present and will be removed afterwards
    public virtual void migrate(long old_version) {
    }

    public QueryBuilder select(Column[]? columns = null) {
        ensure_init();
        return new QueryBuilder(this).select(columns);
    }

    internal MatchQueryBuilder match_query(Table table) {
        ensure_init();
        return new MatchQueryBuilder(this, table);
    }

    public InsertBuilder insert() {
        ensure_init();
        return new InsertBuilder(this);
    }

    public UpdateBuilder update(Table table) {
        ensure_init();
        return new UpdateBuilder(this, table);
    }

    public UpsertBuilder upsert(Table table) {
        ensure_init();
        return new UpsertBuilder(this, table);
    }

    public UpdateBuilder update_named(string table) {
        ensure_init();
        return new UpdateBuilder.for_name(this, table);
    }

    public DeleteBuilder delete() {
        ensure_init();
        return new DeleteBuilder(this);
    }

    public RowIterator query_sql(string sql, string[]? args = null) {
        ensure_init();
        return new RowIterator(this, sql, args);
    }

    internal Statement prepare(string sql) {
        ensure_init();
        Sqlite.Statement statement;
        if (db.prepare_v2(sql, sql.length, out statement) != OK) {
            error("SQLite error: %d - %s: %s", db.errcode(), db.errmsg(), sql);
        }
        return statement;
    }

    public void exec(string sql) throws Error {
        ensure_init();
        if (db.exec(sql) != OK) {
            throw new Error(-1, 0, "SQLite error: %d - %s", db.errcode(), db.errmsg());
        }
    }

    public bool is_known_column(string table, string field) {
        ensure_init();
        foreach (Table t in tables) {
            if (t.is_known_column(field)) return true;
        }
        return false;
    }
}

}
