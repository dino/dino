using Sqlite;

namespace Qlite {

public abstract class Column<T> {
    public const string DEFALT_TABLE_NAME = "";

    public string name { get; private set; }
    public string? default { get; set; }
    public int sqlite_type { get; private set; }
    public bool primary_key { get; set; }
    public bool auto_increment { get; set; }
    public bool unique { get; set; }
    public virtual bool not_null { get; set; }
    public long min_version { get; set; default = -1; }
    public long max_version { get; set; default = long.MAX; }
    internal Table table { get; set; }

    public abstract T get(Row row, string? table_name = DEFALT_TABLE_NAME);

    public virtual bool is_null(Row row, string? table_name = DEFALT_TABLE_NAME) {
        return false;
    }

    internal abstract void bind(Statement stmt, int index, T value);

    public string to_string() {
        return table == null ? name : (table.name + "." + name);
    }

    public string to_column_definition() {
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
        if (default != null) res += @" DEFAULT $((!) default)";

        return res;
    }

    Column(string name, int type) {
        this.name = name;
        this.sqlite_type = type;
    }

    public class Integer : Column<int> {
        public Integer(string name) {
            base(name, INTEGER);
        }

        public override int get(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return (int) row.get_integer(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        public override bool is_null(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return !row.has_integer(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        internal override void bind(Statement stmt, int index, int value) {
            stmt.bind_int(index, value);
        }
    }

    public class Long : Column<long> {
        public Long(string name) {
            base(name, INTEGER);
        }

        public override long get(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return (long) row.get_integer(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        public override bool is_null(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return !row.has_integer(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        internal override void bind(Statement stmt, int index, long value) {
            stmt.bind_int64(index, value);
        }
    }

    public class NullableReal : Column<double?> {
        public NullableReal(string name) {
            base(name, FLOAT);
        }

        public override bool not_null { get { return false; } set {} }

        public override double? get(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return row.get_real(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        public override bool is_null(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return !row.has_real(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        internal override void bind(Statement stmt, int index, double? value) {
            stmt.bind_double(index, value);
        }
    }

    public class Text : Column<string?> {
        public Text(string name) {
            base(name, TEXT);
        }

        public override string? get(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return row.get_text(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        public override bool is_null(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return get(row, table_name == DEFALT_TABLE_NAME ? table.name : table_name) == null;
        }

        internal override void bind(Statement stmt, int index, string? value) {
            if (value != null) {
                stmt.bind_text(index, (!) value);
            } else {
                stmt.bind_null(index);
            }
        }
    }

    public class NonNullText : Column<string> {
        public NonNullText(string name) {
            base(name, TEXT);
        }

        public override bool not_null { get { return true; } set {} }

        public override string get(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return (!)row.get_text(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name);
        }

        public override bool is_null(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return false;
        }

        internal override void bind(Statement stmt, int index, string value) {
            stmt.bind_text(index, (!) value);
        }
    }

    public class BoolText : Column<bool> {
        public BoolText(string name) {
            base(name, TEXT);
        }

        public override bool get(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return row.get_text(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name) == "1";
        }

        internal override void bind(Statement stmt, int index, bool value) {
            stmt.bind_text(index, value ? "1" : "0");
        }
    }

    public class BoolInt : Column<bool> {
        public BoolInt(string name) {
            base(name, INTEGER);
        }

        public override bool get(Row row, string? table_name = DEFALT_TABLE_NAME) {
            return row.get_integer(name, table_name == DEFALT_TABLE_NAME ? table.name : table_name) == 1;
        }

        internal override void bind(Statement stmt, int index, bool value) {
            stmt.bind_int(index, value ? 1 : 0);
        }
    }
}

}
