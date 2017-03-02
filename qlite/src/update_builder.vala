using Sqlite;

namespace Qlite {

public class UpdateBuilder : StatementBuilder {

    // UPDATE [OR ...]
    private string or_val;

    // [...]
    private Table table;
    private string table_name;

    // SET [...]
    private StatementBuilder.Field[] fields;

    // WHERE [...]
    private string selection;
    private StatementBuilder.Field[] selection_args;

    protected UpdateBuilder(Database db, Table table) {
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
        if (fields == null) {
            fields = { new StatementBuilder.Field<T>(column, value) };
        } else {
            StatementBuilder.Field[] fields_new = new StatementBuilder.Field[fields.length+1];
            for (int i = 0; i < fields.length; i++) {
                fields_new[i] = fields[i];
            }
            fields_new[fields.length] = new Field<T>(column, value);
            fields = fields_new;
        }
        return this;
    }

    public UpdateBuilder set_null<T>(Column<T> column) {
        if (column.not_null) throw new DatabaseError.ILLEGAL_QUERY(@"Can't set non-null column $(column.name) to null");
        if (fields == null) {
            fields = { new NullField<T>(column) };
        } else {
            StatementBuilder.Field[] fields_new = new StatementBuilder.Field[fields.length+1];
            for (int i = 0; i < fields.length; i++) {
                fields_new[i] = fields[i];
            }
            fields_new[fields.length] = new NullField<T>(column);
            fields = fields_new;
        }
        return this;
    }

    public UpdateBuilder where(string selection, string[]? selection_args = null) {
        if (selection != null) throw new DatabaseError.ILLEGAL_QUERY("selection was already done, but where() was called.");
        this.selection = selection;
        if (selection_args != null) {
            this.selection_args = new StatementBuilder.Field[selection_args.length];
            for (int i = 0; i < selection_args.length; i++) {
                this.selection_args[i] = new StatementBuilder.StringField(selection_args[i]);
            }
        }
        return this;
    }

    public UpdateBuilder with<T>(Column<T> column, string comp, T value) {
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

    public UpdateBuilder with_null<T>(Column<T> column) {
        selection = @"($selection) AND $(column.name) ISNULL";
        return this;
    }

    public UpdateBuilder without_null<T>(Column<T> column) {
        selection = @"($selection) AND $(column.name) NOT NULL";
        return this;
    }

    public override Statement prepare() throws DatabaseError {
        string sql = "UPDATE";
        if (or_val != null) sql += @" OR $or_val";
        sql += @" $table_name SET ";
        for (int i = 0; i < fields.length; i++) {
            if (i != 0) {
                sql += ", ";
            }
            sql += @"$(fields[i].column.name) = ?";
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

    public void perform() throws DatabaseError {
        if (prepare().step() != DONE) {
            throw new DatabaseError.EXEC_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
        }
    }

}

}