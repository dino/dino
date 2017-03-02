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
        if (text_map.contains(field)) {
            return text_map[field];
        }
        return null;
    }

    public long get_integer(string field) {
        return int_map[field];
    }

    public bool has_integer(string field) {
        return int_map.contains(field);
    }

    public double get_real(string field) {
        return real_map[field];
    }

    public bool has_real(string field) {
        return real_map.contains(field) && real_map[field] != null;
    }

    public class RowIterator {
        private Statement stmt;

        public RowIterator.from_query_builder(QueryBuilder query) throws DatabaseError {
            this.stmt = query.prepare();
        }

        public RowIterator(Database db, string sql, string[]? args = null) {
            this.stmt = db.prepare(sql);
            if (args != null) {
                for (int i = 0; i < args.length; i++) {
                    stmt.bind_text(i, sql, sql.length);
                }
            }
        }

        public Row? next_value() {
            if (stmt.step() == Sqlite.ROW) {
                return new Row(stmt);
            }
            return null;
        }
    }
}

}