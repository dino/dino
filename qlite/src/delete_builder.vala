using Sqlite;

namespace Qlite {

public class DeleteBuilder : StatementBuilder {

    // DELETE FROM [...]
    private Table table;
    private string table_name;

    // WHERE [...]
    private string selection;
    private StatementBuilder.Field[] selection_args;

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

    public DeleteBuilder with<T>(Column<T> column, string comp, T value) {
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

    internal override Statement prepare() throws DatabaseError {
        Statement stmt = db.prepare(@"DELETE FROM $table_name $(selection != null ? @"WHERE $selection": "")");
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