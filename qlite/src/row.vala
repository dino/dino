using Gee;
using Sqlite;

namespace Qlite {

public class Row {
    private Map<string, string?> text_map = new HashMap<string, string?>();
    private Map<string, long> int_map = new HashMap<string, long>();
    private Map<string, double?> real_map = new HashMap<string, double?>();

    internal Row(Statement stmt) {
        for (int i = 0; i < stmt.column_count(); i++) {
            string column_name;
            if (stmt.column_origin_name(i) != null) {
                column_name = @"$(stmt.column_table_name(i)).$(stmt.column_origin_name(i))";
            } else {
                column_name = stmt.column_name(i);
            }
            switch(stmt.column_type(i)) {
                case TEXT:
                    text_map[column_name] = stmt.column_text(i);
                    break;
                case INTEGER:
                    int_map[column_name] = (long) stmt.column_int64(i);
                    break;
                case FLOAT:
                    real_map[column_name] = stmt.column_double(i);
                    break;
            }
        }
    }

    public T get<T>(Column<T> field) {
        return field[this];
    }

    private string field_name(string field, string? table) {
        if (table != null) {
            return @"$table.$field";
        } else {
            return field;
        }
    }

    public string? get_text(string field, string? table = null) {
        if (text_map.has_key(field_name(field, table))) {
            return text_map[field_name(field, table)];
        }
        return null;
    }

    public long get_integer(string field, string? table = null) {
        return int_map[field_name(field, table)];
    }

    public bool has_integer(string field, string? table = null) {
        return int_map.has_key(field_name(field, table));
    }

    public double get_real(string field, string? table = null, double def = 0) {
        return real_map[field_name(field, table)] ?? def;
    }

    public bool has_real(string field, string? table = null) {
        return real_map.has_key(field_name(field, table)) && real_map[field_name(field, table)] != null;
    }

    public string to_string() {
        string ret = "{";

        foreach (string key in text_map.keys) {
            if (ret.length > 1) ret += ", ";
            ret = @"$ret$key: \"$(text_map[key])\"";
        }
        foreach (string key in int_map.keys) {
            if (ret.length > 1) ret += ", ";
            ret = @"$ret$key: $(int_map[key])";
        }
        foreach (string key in real_map.keys) {
            if (ret.length > 1) ret += ", ";
            ret = @"$ret$key: $(real_map[key])";
        }

        return ret + "}";
    }
}

public class RowIterator {
    private Database db;
    private Statement stmt;

    public RowIterator.from_query_builder(Database db, QueryBuilder query) {
        this.db = db;
        this.stmt = query.prepare();
    }

    public RowIterator(Database db, string sql, string[]? args = null) {
        this.db = db;
        this.stmt = db.prepare(sql);
        if (args != null) {
            for (int i = 0; i < args.length; i++) {
                stmt.bind_text(i, sql, sql.length);
            }
        }
    }

    public bool next() {
        int r = stmt.step();
        if (r == Sqlite.ROW) return true;
        if (r == Sqlite.DONE) return false;
        print(@"SQLite error: $(db.errcode()) - $(db.errmsg())\n");
        return false;
    }

    public Row get() {
        return new Row(stmt);
    }

    public Row? get_next() {
        if (next()) return get();
        return null;
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
        if (inner == null || field.is_null((!)inner)) return def;
        return field[(!)inner];
    }

    internal long get_integer(string field, long def = 0) {
        if (inner == null || !((!)inner).has_integer(field)) return def;
        return ((!)inner).get_integer(field);
    }
}

}
