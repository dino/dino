using Sqlite;

namespace Qlite {

public class UpsertBuilder : StatementBuilder {
    // INTO [...]
    private Table table;
    private string table_name;

    // VALUES [...]
    private StatementBuilder.AbstractField[] keys = {};
    private StatementBuilder.AbstractField[] fields = {};

    internal UpsertBuilder(Database db, Table table) {
        base(db);
        this.table = table;
        this.table_name = table.name;
    }

    public UpsertBuilder value<T>(Column<T> column, T value, bool key = false) {
        if (key) {
            keys += new Field<T>(column, value);
        } else {
            fields += new Field<T>(column, value);
        }
        return this;
    }

    public UpsertBuilder value_null<T>(Column<T> column) throws DatabaseError {
        if (column.not_null) throw new DatabaseError.ILLEGAL_QUERY(@"Can't set non-null column $(column.name) to null");
        fields += new NullField<T>(column);
        return this;
    }

    internal override Statement prepare() throws DatabaseError {
        throw new DatabaseError.NOT_SUPPORTED("prepare() not available for upsert.");
    }

    internal Statement prepare_update() {
        string update_set_list = "";
        string update_where_list = "";
        for (int i = 0; i < fields.length; i++) {
            if (i != 0) {
                update_set_list += ", ";
            }
            update_set_list += @"$(((!)fields[i].column).name) = ?";
        }
        for (int i = 0; i < keys.length; i++) {
            if (i != 0) {
                update_where_list += " AND ";
            }
            update_where_list += @"$(((!)keys[i].column).name) = ?";
        }

        string sql = @"UPDATE $table_name SET $update_set_list WHERE $update_where_list";

        Statement stmt = db.prepare(sql);
        for (int i = 0; i < fields.length; i++) {
            fields[i].bind(stmt, i + 1);
        }
        for (int i = 0; i < keys.length; i++) {
            keys[i].bind(stmt, i + fields.length + 1);
        }

        return stmt;
    }

    internal Statement prepare_insert() {
        string insert_field_list = "";
        string insert_value_qs = "";
        for (int i = 0; i < fields.length; i++) {
            if (i != 0) {
                insert_value_qs += ", ";
                insert_field_list += ", ";
            }
            insert_field_list += ((!)fields[i].column).name;
            insert_value_qs += "?";
        }
        for (int i = 0; i < keys.length; i++) {
            if (i != 0 || fields.length > 0) {
                insert_value_qs += ", ";
                insert_field_list += ", ";
            }
            insert_field_list += ((!)keys[i].column).name;
            insert_value_qs += "?";
        }

        string sql = @"INSERT OR IGNORE INTO $table_name ($insert_field_list) VALUES ($insert_value_qs)";

        Statement stmt = db.prepare(sql);
        for (int i = 0; i < fields.length; i++) {
            fields[i].bind(stmt, i + 1);
        }
        for (int i = 0; i < keys.length; i++) {
            keys[i].bind(stmt, i + fields.length + 1);
        }

        return stmt;
    }

    public int64 perform() throws DatabaseError {
        if (prepare_update().step() != DONE || prepare_insert().step() != DONE) {
            throw new DatabaseError.EXEC_ERROR(@"SQLite error: $(db.errcode()) - $(db.errmsg())");
        }
        return db.last_insert_rowid();
    }

}

}