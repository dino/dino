using Sqlite;

namespace Qlite {

public abstract class Column<T> {
    public string name { get; private set; }
    public string default { get; set; }
    public int sqlite_type { get; private set; }
    public bool primary_key { get; set; }
    public bool auto_increment { get; set; }
    public bool unique { get; set; }
    public bool not_null { get; set; }
    public long min_version { get; set; default = -1; }
    public long max_version { get; set; default = long.MAX; }

    public abstract T get(Row row);

    public virtual bool is_null(Row row) {
        return false;
    }

    public virtual void bind(Statement stmt, int index, T value) {
        throw new DatabaseError.NOT_SUPPORTED(@"bind() was not implemented for field $name");
    }

    public string to_string() {
        string res = name;
        switch (sqlite_type) {
            case INTEGER:
                res += " INTEGER";
                break;
            case FLOAT:
                res += " REAL";
                break;
            case TEXT:
                res += " TEXT";
                break;
            default:
                res += " UNKNOWN";
                break;
        }
        if (primary_key) {
            res += " PRIMARY KEY";
            if (auto_increment) res += " AUTOINCREMENT";
        }
        if (not_null) res += " NOT NULL";
        if (unique) res += " UNIQUE";
        if (default != null) res += @" DEFAULT $default";

        return res;
    }

    public Column(string name, int type) {
        this.name = name;
        this.sqlite_type = type;
    }

    public class Integer : Column<int> {
        public Integer(string name) {
            base(name, INTEGER);
        }

        public override int get(Row row) {
            return (int) row.get_integer(name);
        }

        public override bool is_null(Row row) {
            return !row.has_integer(name);
        }

        public override void bind(Statement stmt, int index, int value) {
            stmt.bind_int(index, value);
        }
    }

    public class Long : Column<long> {
        public Long(string name) {
            base(name, INTEGER);
        }

        public override long get(Row row) {
            return (long) row.get_integer(name);
        }

        public override bool is_null(Row row) {
            return !row.has_integer(name);
        }

        public override void bind(Statement stmt, int index, long value) {
            stmt.bind_int64(index, value);
        }
    }

    public class Real : Column<double> {
        public Real(string name) {
            base(name, FLOAT);
        }

        public override double get(Row row) {
            return row.get_real(name);
        }

        public override bool is_null(Row row) {
            return !row.has_real(name);
        }

        public override void bind(Statement stmt, int index, double value) {
            stmt.bind_double(index, value);
        }
    }

    public class Text : Column<string?> {
        public Text(string name) {
            base(name, TEXT);
        }

        public override string? get(Row row) {
            return row.get_text(name);
        }

        public override bool is_null(Row row) {
            return get(row) == null;
        }

        public override void bind(Statement stmt, int index, string? value) {
            if (value != null) {
                stmt.bind_text(index, value);
            } else {
                stmt.bind_null(index);
            }
        }
    }

    public class BoolText : Column<bool> {
        public BoolText(string name) {
            base(name, TEXT);
        }

        public override bool get(Row row) {
            return row.get_text(name) == "1";
        }

        public override void bind(Statement stmt, int index, bool value) {
            stmt.bind_text(index, value ? "1" : "0");
        }
    }

    public class BoolInt : Column<bool> {
        public BoolInt(string name) {
            base(name, INTEGER);
        }

        public override bool get(Row row) {
            return row.get_integer(name) == 1;
        }

        public override void bind(Statement stmt, int index, bool value) {
            stmt.bind_int(index, value ? 1 : 0);
        }
    }

    public class RowReference : Column<Row?> {
        private Table table;
        private Column<int> id_column;

        public RowReference(string name, Table table, Column<int> id_column) throws DatabaseError {
            base(name, INTEGER);
            if (!table.is_known_column(id_column.name)) throw new DatabaseError.ILLEGAL_REFERENCE(@"$(id_column.name) is not a column in $(table.name)");
            if (!id_column.primary_key && !id_column.unique) throw new DatabaseError.NON_UNIQUE(@"$(id_column.name) is not suited to identify a row, but used with RowReference");
            this.table = table;
            this.id_column = id_column;
        }

        public override Row? get(Row row) {
            return table.row_with(id_column, (int)row.get_integer(name));
        }

        public override void bind(Statement stmt, int index, Row? value) {
            if (value != null) {
                stmt.bind_int(index, id_column.get(value));
            } else {
                stmt.bind_null(index);
            }
        }
    }
}

}