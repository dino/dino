using Sqlite;

namespace Qlite {

public class InsertBuilder : StatementBuilder {

    // INSERT [OR ...]
    private bool replace_val;
    private string or_val;

    // INTO [...]
    private Table table;
    private string table_name;

    // VALUES [...]
    private StatementBuilder.Field[] fields;

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

    public InsertBuilder value_null<T>(Column<T> column) throws DatabaseError {
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

    internal override Statement prepare() throws DatabaseError {
        string fields_text = "";
        string value_qs = "";
        for (int i = 0; i < fields.length; i++) {
            if (i != 0) {
                value_qs += ", ";
                fields_text += ", ";
            }
            fields_text += fields[i].column.name;
            value_qs += "?";
        }
        string sql = replace_val ? "REPLACE" : "INSERT";
        if (!replace_val && or_val != null) sql += @" OR $or_val";
        sql += @" INTO $table_name ( $fields_text ) VALUES ($value_qs)";
        Statement stmt = db.prepare(sql);
        for (int i = 0; i < fields.length; i++) {
            fields[i].bind(stmt, i+1);
        }
        return stmt;
    }

    public int64 perform() throws DatabaseError {
        if (prepare().step() != DONE) {
            throw new DatabaseError.EXEC_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
        }
        return db.last_insert_rowid();
    }

}

}