using Sqlite;

namespace Qlite {

public class DeleteBuilder : StatementBuilder {

    // DELETE FROM [...]
    private Table? table;
    private string table_name;

    // WHERE [...]
    private string selection = "1";
    private StatementBuilder.AbstractField[] selection_args = {};

    internal DeleteBuilder(Database db) {
        base(db);
    }

    public DeleteBuilder from(Table table) throws DatabaseError {
        if (this.table != null) throw new DatabaseError.ILLEGAL_QUERY("cannot use from() multiple times.");
        this.table = table;
        this.table_name = table.name;
        return this;
    }

    public DeleteBuilder from_name(string table) {
        this.table_name = table;
        return this;
    }

    public DeleteBuilder where(string selection, string[]? selection_args = null) throws DatabaseError {
        if (this.selection != "1") throw new DatabaseError.ILLEGAL_QUERY("selection was already done, but where() was called.");
        this.selection = selection;
        foreach (string arg in selection_args) {
            this.selection_args += new StatementBuilder.StringField(arg);
        }
        return this;
    }

    public DeleteBuilder with<T>(Column<T> column, string comp, T value) {
        selection_args += new Field<T>(column, value);
        selection = @"($selection) AND $(column.name) $comp ?";
        return this;
    }

    internal override Statement prepare() throws DatabaseError {
        Statement stmt = db.prepare(@"DELETE FROM $table_name WHERE $selection");
        for (int i = 0; i < selection_args.length; i++) {
            selection_args[i].bind(stmt, i+1);
        }
        return stmt;
    }

    public void perform() throws DatabaseError {
        if (prepare().step() != DONE) {
            throw new DatabaseError.EXEC_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
        }
    }

}

}