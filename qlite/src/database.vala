using Sqlite;

namespace Qlite {

public errordomain DatabaseError {
    ILLEGAL_QUERY,
    NOT_SUPPORTED,
    OPEN_ERROR,
    PREPARE_ERROR,
    EXEC_ERROR,
    NON_UNIQUE,
    ILLEGAL_REFERENCE,
    NOT_INITIALIZED
}

public class Database {
    private string file_name;
    private Sqlite.Database db;
    private long expected_version;
    private Table[] tables;

    private Column<string> meta_name = new Column.Text("name") { primary_key = true };
    private Column<long> meta_int_val = new Column.Long("int_val");
    private Column<string> meta_text_val = new Column.Text("text_val");
    private Table meta_table;

    public bool debug = false;

    public Database(string file_name, long expected_version) {
        this.file_name = file_name;
        this.expected_version = expected_version;
        meta_table = new Table(this, "_meta");
        meta_table.init({meta_name, meta_int_val, meta_text_val});
    }

    public void init(Table[] tables) throws DatabaseError {
        Sqlite.config(Config.SERIALIZED);
        int ec = Sqlite.Database.open_v2(file_name, out db, OPEN_READWRITE | OPEN_CREATE | 0x00010000);
        if (ec != Sqlite.OK) {
            throw new DatabaseError.OPEN_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
        }
        this.tables = tables;
        start_migration();
    }

    public void ensure_init() throws DatabaseError {
        if (tables == null) throw new DatabaseError.NOT_INITIALIZED(@"Database $file_name was not initialized, call init()");
    }

    private void start_migration() throws DatabaseError {
        meta_table.create_table_at_version(expected_version);
        long old_version = 0;
        try {
            Row? row = meta_table.row_with(meta_name, "version");
            old_version = row == null ? -1 : (long) row[meta_int_val];
        } catch (DatabaseError e) {
            old_version = -1;
        }
        foreach (Table t in tables) {
            t.create_table_at_version(old_version);
        }
        if (expected_version != old_version) {
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
    public virtual void migrate(long old_version) throws DatabaseError {
    }

    public QueryBuilder select(Column[]? columns = null) throws DatabaseError {
        ensure_init();
        return new QueryBuilder(this).select(columns);
    }

    public InsertBuilder insert() throws DatabaseError {
        ensure_init();
        return new InsertBuilder(this);
    }

    public UpdateBuilder update(Table table) throws DatabaseError {
        ensure_init();
        return new UpdateBuilder(this, table);
    }

    public UpdateBuilder update_named(string table) throws DatabaseError {
        ensure_init();
        return new UpdateBuilder.for_name(this, table);
    }

    public DeleteBuilder delete() throws DatabaseError {
        ensure_init();
        return new DeleteBuilder(this);
    }

    public Row.RowIterator query_sql(string sql, string[]? args = null) throws DatabaseError {
        ensure_init();
        return new Row.RowIterator(this, sql, args);
    }

    public Statement prepare(string sql) throws DatabaseError {
        ensure_init();
        if (debug) print(@"prepare: $sql\n");
        Sqlite.Statement statement;
        if (db.prepare_v2(sql, sql.length, out statement) != OK) {
            throw new DatabaseError.PREPARE_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
        }
        return statement;
    }

    public void exec(string sql) throws DatabaseError {
        ensure_init();
        if (db.exec(sql) != OK) {
            throw new DatabaseError.EXEC_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
        }
    }

    public bool is_known_column(string table, string field) throws DatabaseError {
        ensure_init();
        foreach (Table t in tables) {
            if (t.is_known_column(field)) return true;
        }
        return false;
    }
}

}