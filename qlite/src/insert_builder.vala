using Sqlite;

namespace Qlite {

public class InsertBuilder : StatementBuilder {

    // INSERT [OR ...]
    private bool replace_val;
    private string? or_val;

    // INTO [...]
    private Table table;
    private string table_name;

    // VALUES [...]
    private StatementBuilder.AbstractField[] fields = {};

    internal InsertBuilder(Database db) {
        base(db);
    }

    public InsertBuilder replace() {
        this.replace_val = true;
        return this;
    }

    public InsertBuilder or(string or) {
        this.or_val = or;
        return this;
    }

    public InsertBuilder into(Table table) {
        this.table = table;
        this.table_name = table.name;
        return this;
    }

    public InsertBuilder into_name(string table) {
        this.table_name = table;
        return this;
    }

    public InsertBuilder value<T>(Column<T> column, T value) {
        fields += new Field<T>(column, value);
        return this;
    }

    public InsertBuilder value_null<T>(Column<T> column) {
        if (column.not_null) error("Qlite Error: ILLEGAL QUERY: Can't set non-null column %s to null", column.name);
        fields += new NullField<T>(column);
        return this;
    }

    internal override Statement prepare() {
        string fields_text = "";
        string value_qs = "";
        for (int i = 0; i < fields.length; i++) {
            if (i != 0) {
                value_qs += ", ";
                fields_text += ", ";
            }
            fields_text += ((!)fields[i].column).name;
            value_qs += "?";
        }
        string sql = replace_val ? "REPLACE" : "INSERT";
        if (!replace_val && or_val != null) sql += @" OR $((!)or_val)";
        sql += @" INTO $table_name ( $fields_text ) VALUES ($value_qs)";
        Statement stmt = db.prepare(sql);
        for (int i = 0; i < fields.length; i++) {
            fields[i].bind(stmt, i+1);
        }
        return stmt;
    }

    public int64 perform() {
        if (prepare().step() != DONE) {
            error(@"SQLite error: %d - %s", db.errcode(), db.errmsg());
        }
        return db.last_insert_rowid();
    }

}

}
