using Sqlite;

namespace Qlite {

public class UpdateBuilder : StatementBuilder {

    // UPDATE [OR ...]
    private string? or_val;

    // [...]
    private Table? table;
    private string table_name;

    // SET [...]
    private StatementBuilder.AbstractField[] fields = {};

    // WHERE [...]
    private string selection = "1";
    private StatementBuilder.AbstractField[] selection_args = {};

    internal UpdateBuilder(Database db, Table table) {
        base(db);
        this.table = table;
        this.table_name = table.name;
    }

    internal UpdateBuilder.for_name(Database db, string table) {
        base(db);
        this.table_name = table;
    }

    public UpdateBuilder or(string or) {
        this.or_val = or;
        return this;
    }

    public UpdateBuilder set<T>(Column<T> column, T value) {
        fields += new Field<T>(column, value);
        return this;
    }

    public UpdateBuilder set_null<T>(Column<T> column) {
        if (column.not_null) error("Can't set non-null column %s to null", column.name);
        fields += new NullField<T>(column);
        return this;
    }

    public UpdateBuilder where(string selection, string[] selection_args = {}) {
        if (this.selection != "1") error("selection was already done, but where() was called.");
        this.selection = selection;
        foreach (string arg in selection_args) {
            this.selection_args += new StatementBuilder.StringField(arg);
        }
        return this;
    }

    public UpdateBuilder with<T>(Column<T> column, string comp, T value) {
        selection_args += new Field<T>(column, value);
        selection = @"($selection) AND $(column.name) $comp ?";
        return this;
    }

    public UpdateBuilder with_null<T>(Column<T> column) {
        selection = @"($selection) AND $(column.name) ISNULL";
        return this;
    }

    public UpdateBuilder without_null<T>(Column<T> column) {
        selection = @"($selection) AND $(column.name) NOT NULL";
        return this;
    }

    internal override Statement prepare() {
        string sql = "UPDATE";
        if (or_val != null) sql += @" OR $((!)or_val)";
        sql += @" $table_name SET ";
        for (int i = 0; i < fields.length; i++) {
            if (i != 0) {
                sql += ", ";
            }
            sql += @"$(((!)fields[i].column).name) = ?";
        }
        sql += @" WHERE $selection";
        Statement stmt = db.prepare(sql);
        for (int i = 0; i < fields.length; i++) {
            fields[i].bind(stmt, i+1);
        }
        for (int i = 0; i < selection_args.length; i++) {
            selection_args[i].bind(stmt, i + fields.length + 1);
        }
        return stmt;
    }

    public void perform() {
        if (fields.length == 0) return;
        if (prepare().step() != DONE) {
            error("SQLite error: %d - %s", db.errcode(), db.errmsg());
        }
    }

}

}
