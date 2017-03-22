using Gee;
using Sqlite;

namespace Qlite {

public class Row {
    private Map<string, string> text_map = new HashMap<string, string>();
    private Map<string, long> int_map = new HashMap<string, long>();
    private Map<string, double?> real_map = new HashMap<string, double?>();

    public Row(Statement stmt) {
        for (int i = 0; i < stmt.column_count(); i++) {
            switch(stmt.column_type(i)) {
                case TEXT:
                    text_map[stmt.column_name(i)] = stmt.column_text(i);
                    break;
                case INTEGER:
                    int_map[stmt.column_name(i)] = (long) stmt.column_int64(i);
                    break;
                case FLOAT:
                    real_map[stmt.column_name(i)] = stmt.column_double(i);
                    break;
            }
        }
    }

    public T get<T>(Column<T> field) {
        return field[this];
    }

    public string? get_text(string field) {
        if (text_map.has_key(field)) {
            return text_map[field];
        }
        return null;
    }

    public long get_integer(string field) {
        return int_map[field];
    }

    public bool has_integer(string field) {
        return int_map.has_key(field);
    }

    public double get_real(string field) {
        return real_map[field];
    }

    public bool has_real(string field) {
        return real_map.has_key(field) && real_map[field] != null;
    }
}

public class RowIterator {
    private Database db;
    private Statement stmt;

    public RowIterator.from_query_builder(Database db, QueryBuilder query) throws DatabaseError {
        this.db = db;
        this.stmt = query.prepare();
    }

    public RowIterator(Database db, string sql, string[]? args = null) throws DatabaseError {
        this.db = db;
        this.stmt = db.prepare(sql);
        if (args != null) {
            for (int i = 0; i < args.length; i++) {
                stmt.bind_text(i, sql, sql.length);
            }
        }
    }

    public Row? next_value() throws DatabaseError {
        int r = stmt.step();
        if (r == Sqlite.ROW) return new Row(stmt);
        if (r == Sqlite.DONE) return null;
        throw new DatabaseError.EXEC_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
    }
}

public class RowOption {
    public Row? inner { get; private set; }

    public RowOption(Row? row) {
        this.inner = row;
    }

    public bool is_present() {
        return inner != null;
    }

    public T get<T>(Column<T> field, T def = null) {
        if (inner == null || field.is_null(inner)) return def;
        return field[inner];
    }
}

}