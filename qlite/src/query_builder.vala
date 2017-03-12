using Sqlite;

namespace Qlite {

public class QueryBuilder : StatementBuilder {
    private bool single_result;

    // SELECT [...]
    private string column_selector = "*";
    private Column[] columns;

    // FROM [...]
    private Table table;
    private string table_name;

    // WHERE [...]
    private string selection;
    private StatementBuilder.Field[] selection_args;

    // ORDER BY [...]
    private OrderingTerm[] order_by_terms;

    // LIMIT [...]
    private int limit_val;

    protected QueryBuilder(Database db) {
        base(db);
    }

    public QueryBuilder select(Column[]? columns = null) {
        this.columns = columns;
        if (columns != null) {
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
        this.columns = null;
        this.column_selector = column_selector;
        return this;
    }

    public QueryBuilder from(Table table) throws DatabaseError {
        if (this.table_name != null) throw new DatabaseError.ILLEGAL_QUERY("cannot use from() multiple times.");
        this.table = table;
        this.table_name = table.name;
        return this;
    }

    public QueryBuilder from_name(string table) {
        this.table_name = table;
        return this;
    }

    public QueryBuilder where(string selection, string[]? selection_args = null) throws DatabaseError {
        if (this.selection != null) throw new DatabaseError.ILLEGAL_QUERY("selection was already done, but where() was called.");
        this.selection = selection;
        if (selection_args != null) {
            this.selection_args = new StatementBuilder.Field[selection_args.length];
            for (int i = 0; i < selection_args.length; i++) {
                this.selection_args[i] = new StatementBuilder.StringField(selection_args[i]);
            }
        }
        return this;
    }

    public QueryBuilder with<T>(Column<T> column, string comp, T value) {
        if ((column.unique || column.primary_key) && comp == "=") single_result = true;
        if (selection == null) {
            selection = @"$(column.name) $comp ?";
            selection_args = { new StatementBuilder.Field<T>(column, value) };
        } else {
            selection = @"($selection) AND $(column.name) $comp ?";
            StatementBuilder.Field[] selection_args_new = new StatementBuilder.Field[selection_args.length+1];
            for (int i = 0; i < selection_args.length; i++) {
                selection_args_new[i] = selection_args[i];
            }
            selection_args_new[selection_args.length] = new Field<T>(column, value);
            selection_args = selection_args_new;
        }
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

    private void add_order_by(OrderingTerm term) {
        if (order_by_terms == null) {
            order_by_terms = { term };
        } else {
            OrderingTerm[] order_by_terms_new = new OrderingTerm[order_by_terms.length+1];
            for (int i = 0; i < order_by_terms.length; i++) {
                order_by_terms_new[i] = order_by_terms[i];
            }
            order_by_terms_new[order_by_terms.length] = term;
            order_by_terms = order_by_terms_new;
        }
    }

    public QueryBuilder order_by(Column column, string dir = "ASC") {
        add_order_by(new OrderingTerm(column, dir));
        return this;
    }

    public QueryBuilder order_by_name(string name, string dir) {
        add_order_by(new OrderingTerm.by_name(name, dir));
        return this;
    }

    public QueryBuilder limit(int limit) {
        this.limit_val = limit;
        return this;
    }

    public int64 count() throws DatabaseError {
        this.column_selector = @"COUNT($column_selector) AS count";
        this.single_result = true;
        return row_().get_integer("count");
    }

    private Row? row_() throws DatabaseError {
        if (!single_result) throw new DatabaseError.NON_UNIQUE("query is not suited to return a single row, but row() was called.");
        return iterator().next_value();
    }

    public RowOption row() throws DatabaseError {
        return new RowOption(row_());
    }

    public T get<T>(Column<T> field) throws DatabaseError {
        return row()[field];
    }

    public override Statement prepare() throws DatabaseError {
        Statement stmt = db.prepare(@"SELECT $column_selector FROM $table_name $(selection != null ? @"WHERE $selection" : "") $(order_by_terms != null ? OrderingTerm.all_to_string(order_by_terms) : "") $(limit_val > 0 ? @" LIMIT $limit_val" : "")");
        for (int i = 0; i < selection_args.length; i++) {
            selection_args[i].bind(stmt, i+1);
        }
        return stmt;
    }

    public RowIterator iterator() throws DatabaseError {
        return new RowIterator.from_query_builder(this);
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

        public static string all_to_string(OrderingTerm[] terms) {
            if (terms.length == 0) return "";
            string res = "ORDER BY "+terms[0].to_string();
            for (int i = 1; i < terms.length; i++) {
                res += @", $(terms[i])";
            }
            return res;
        }
    }
}

}