using Sqlite;

namespace Qlite {

public class QueryBuilder : StatementBuilder {
    private bool single_result;

    // SELECT [...]
    private string column_selector = "*";
    private Column[] columns = {};

    // FROM [...]
    protected Table? table;
    protected string? table_name;

    // JOIN [...]
    private string joins = "";

    // WHERE [...]
    protected string selection = "1";
    internal StatementBuilder.AbstractField[] selection_args = {};

    // ORDER BY [...]
    private OrderingTerm[]? order_by_terms = {};

    // GROUP BY [...]
    private string? group_by_term;

    // LIMIT [...] OFFSET [...]
    private int limit_val;
    private int offset_val;

    internal QueryBuilder(Database db) {
        base(db);
    }

    public QueryBuilder select(Column[] columns = {}) {
        this.columns = columns;
        if (columns.length != 0) {
            for (int i = 0; i < columns.length; i++) {
                if (column_selector == "*") {
                    column_selector = columns[i].to_string();
                } else {
                    column_selector += ", " + columns[i].to_string();
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

    public virtual QueryBuilder from(Table table) {
        if (this.table_name != null) error("cannot use from() multiple times.");
        this.table = table;
        this.table_name = table.name;
        return this;
    }

    public virtual QueryBuilder from_name(string table) {
        this.table_name = table;
        return this;
    }

    public QueryBuilder outer_join_with<T>(Table table, Column<T> lhs, Column<T> rhs, string? as = null) {
        return outer_join_on(table, @"$lhs = $rhs", as);
    }

    public QueryBuilder outer_join_on(Table table, string on, string? as = null) {
        if (as == null) as = table.name;
        joins += @" LEFT OUTER JOIN $(table.name) AS $as ON $on";
        return this;
    }

    public QueryBuilder join_with<T>(Table table, Column<T> lhs, Column<T> rhs, string? as = null) {
        return join_on(table, @"$lhs = $rhs", as);
    }

    public QueryBuilder join_on(Table table, string on, string? as = null) {
        if (as == null) as = table.name;
        joins += @" JOIN $(table.name) AS $as ON $on";
        return this;
    }

    internal QueryBuilder join_name(string table_name, string on) {
        joins += @" JOIN $table_name ON $on";
        return this;
    }

    public QueryBuilder where(string selection, string[] selection_args = {}) {
        this.selection = @"($(this.selection)) AND ($selection)";
        foreach (string arg in selection_args) {
            this.selection_args += new StatementBuilder.StringField(arg);
        }
        return this;
    }

    public QueryBuilder with<T>(Column<T> column, string comp, T value) {
        if ((column.unique || column.primary_key) && comp == "=") single_result = true;
        selection_args += new Field<T>(column, value);
        selection = @"($selection) AND $column $comp ?";
        return this;
    }

    public QueryBuilder with_null<T>(Column<T> column) {
        selection = @"($selection) AND $column ISNULL";
        return this;
    }

    public QueryBuilder without_null<T>(Column<T> column) {
        selection = @"($selection) AND $column NOT NULL";
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

    public QueryBuilder group_by(Column[] columns) {
        foreach(Column col in columns) {
            if (group_by_term == null) {
                group_by_term = col.to_string();
            } else {
                group_by_term += @", $col";
            }
        }
        return this;
    }

    public QueryBuilder limit(int limit) {
        if (this.limit_val != 0 && limit > this.limit_val) error("tried to increase an existing limit");
        this.limit_val = limit;
        return this;
    }

    public QueryBuilder offset(int offset) {
        if (this.limit_val == 0) error("limit required before offset");
        this.offset_val = offset;
        return this;
    }

    public QueryBuilder single() {
        this.single_result = true;
        return limit(1);
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

    public T get<T>(Column<T> field, T def = null) {
        return row().get(field, def);
    }

    internal override Statement prepare() {
        Statement stmt = db.prepare(@"SELECT $column_selector $(table_name == null ? "" : @"FROM $((!) table_name)") $joins WHERE $selection $(group_by_term == null ? "" : @"GROUP BY $group_by_term") $(OrderingTerm.all_to_string(order_by_terms)) $(limit_val > 0 ? @" LIMIT $limit_val OFFSET $offset_val" : "")");
        for (int i = 0; i < selection_args.length; i++) {
            selection_args[i].bind(stmt, i+1);
        }
        return stmt;
    }

    public RowIterator iterator() {
        return new RowIterator.from_query_builder(db, this);
    }

    class OrderingTerm {
        Column? column;
        string column_name;
        string dir;

        public OrderingTerm(Column column, string dir) {
            this.column = column;
            this.column_name = column.to_string();
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

public class MatchQueryBuilder : QueryBuilder {
    internal MatchQueryBuilder(Database db, Table table) {
        base(db);
        if (table.fts_columns == null) error("MATCH query on non FTS table");
        from(table);
        join_name(@"_fts_$table_name", @"_fts_$table_name.docid = $table_name.rowid");
    }

    public MatchQueryBuilder match(Column<string> column, string match) {
        if (table == null) error("MATCH must occur after FROM statement");
        if (!(column in table.fts_columns)) error("MATCH selection on non FTS column");
        selection_args += new StatementBuilder.StringField(match);
        selection = @"($selection) AND _fts_$table_name.$(column.name) MATCH ?";
        return this;
    }
}

}
