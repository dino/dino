using Sqlite;

namespace Qlite {

public class QueryBuilder : StatementBuilder {
    private bool single_result;

    // SELECT [...]
    private string column_selector = "*";
    private Column[] columns = {};

    // FROM [...]
    private Table? table;
    private string? table_name;

    // WHERE [...]
    private string selection = "1";
    private StatementBuilder.AbstractField[] selection_args = {};

    // ORDER BY [...]
    private OrderingTerm[]? order_by_terms = {};

    // LIMIT [...]
    private int limit_val;

    internal QueryBuilder(Database db) {
        base(db);
    }

    public QueryBuilder select(Column[] columns = {}) {
        this.columns = columns;
        if (columns.length == 0) {
            for (int i = 0; i < columns.length; i++) {
                if (column_selector == "*") {
                    column_selector = columns[0].name;
                } else {
                    column_selector += ", " + columns[i].name;
                }
            }
        } else {
            column_selector = "*";
        }
        return this;
    }

    public QueryBuilder select_string(string column_selector) {
        this.columns = {};
        this.column_selector = column_selector;
        return this;
    }

    public QueryBuilder from(Table table) {
        if (this.table_name != null) error("cannot use from() multiple times.");
        this.table = table;
        this.table_name = table.name;
        return this;
    }

    public QueryBuilder from_name(string table) {
        this.table_name = table;
        return this;
    }

    public QueryBuilder where(string selection, string[] selection_args = {}) {
        if (this.selection != "1") error("selection was already done, but where() was called.");
        this.selection = selection;
        foreach (string arg in selection_args) {
            this.selection_args += new StatementBuilder.StringField(arg);
        }
        return this;
    }

    public QueryBuilder with<T>(Column<T> column, string comp, T value) {
        if ((column.unique || column.primary_key) && comp == "=") single_result = true;
        selection_args += new Field<T>(column, value);
        selection = @"($selection) AND $(column.name) $comp ?";
        return this;
    }

    public QueryBuilder with_null<T>(Column<T> column) {
        selection = @"($selection) AND $(column.name) ISNULL";
        return this;
    }

    public QueryBuilder without_null<T>(Column<T> column) {
        selection = @"($selection) AND $(column.name) NOT NULL";
        return this;
    }

    public QueryBuilder order_by(Column column, string dir = "ASC") {
        order_by_terms += new OrderingTerm(column, dir);
        return this;
    }

    public QueryBuilder order_by_name(string name, string dir) {
        order_by_terms += new OrderingTerm.by_name(name, dir);
        return this;
    }

    public QueryBuilder limit(int limit) {
        this.limit_val = limit;
        return this;
    }

    public int64 count() {
        this.column_selector = @"COUNT($column_selector) AS count";
        this.single_result = true;
        return row().get_integer("count");
    }

    private Row? row_() {
        if (!single_result) error("query is not suited to return a single row, but row() was called.");
        return iterator().get_next();
    }

    public RowOption row() {
        return new RowOption(row_());
    }

    public T get<T>(Column<T> field) {
        return row()[field];
    }

    internal override Statement prepare() {
        Statement stmt = db.prepare(@"SELECT $column_selector $(table_name == null ? "" : @"FROM $((!) table_name)") WHERE $selection $(OrderingTerm.all_to_string(order_by_terms)) $(limit_val > 0 ? @" LIMIT $limit_val" : "")");
        for (int i = 0; i < selection_args.length; i++) {
            selection_args[i].bind(stmt, i+1);
        }
        return stmt;
    }

    public RowIterator iterator() {
        return new RowIterator.from_query_builder(db, this);
    }

    class OrderingTerm {
        Column column;
        string column_name;
        string dir;

        public OrderingTerm(Column column, string dir) {
            this.column = column;
            this.column_name = column.name;
            this.dir = dir;
        }

        public OrderingTerm.by_name(string column_name, string dir) {
            this.column_name = column_name;
            this.dir = dir;
        }

        public string to_string() {
            return @"$column_name $dir";
        }

        public static string all_to_string(OrderingTerm[]? terms) {
            if (terms == null || terms.length == 0) return "";
            string res = "ORDER BY "+terms[0].to_string();
            for (int i = 1; i < terms.length; i++) {
                res += @", $(terms[i])";
            }
            return res;
        }
    }
}

}
