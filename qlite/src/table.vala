using Sqlite;

namespace Qlite {

public class Table {
    protected Database db;
    public string name { get; private set; }
    protected Column[]? columns;
    private string constraints = "";
    private string[] post_statements = {};

    public Table(Database db, string name) {
        this.db = db;
        this.name = name;
    }

    public void init(Column[] columns, string constraints = "") {
        this.columns = columns;
        this.constraints = constraints;
    }

    public void unique(Column[] columns, string? on_conflict = null) {
        constraints += ", UNIQUE (";
        bool first = true;
        foreach (Column c in columns) {
            if (!first) constraints += ", ";
            constraints += c.name;
            first = false;
        }
        constraints += ")";
        if (on_conflict != null) {
            constraints += " ON CONFLICT " + (!)on_conflict;
        }
    }

    public void add_post_statement(string stmt) {
        post_statements += stmt;
    }

    public void index(string index_name, Column[] columns, bool unique = false) {
        string stmt = @"CREATE $(unique ? "UNIQUE" : "") INDEX IF NOT EXISTS $index_name ON $name (";
        bool first = true;
        foreach (Column c in columns) {
            if (!first) stmt += ", ";
            stmt += c.name;
            first = false;
        }
        stmt += ")";
        add_post_statement(stmt);
    }

    private void ensure_init() {
        if (columns == null) error("Table %s was not initialized, call init()", name);
    }

    public QueryBuilder select(Column[]? columns = null) {
        ensure_init();
        return db.select(columns).from(this);
    }

    public InsertBuilder insert() {
        ensure_init();
        return db.insert().into(this);
    }

    public UpdateBuilder update() {
        ensure_init();
        return db.update(this);
    }

    public UpsertBuilder upsert() {
        ensure_init();
        return db.upsert(this);
    }

    public DeleteBuilder delete() {
        ensure_init();
        return db.delete().from(this);
    }

    public RowOption row_with<T>(Column<T> column, T value) {
        ensure_init();
        if (!column.unique && !column.primary_key) error("%s is not suited to identify a row, but used with row_with()", column.name);
        return select().with(column, "=", value).row();
    }

    public bool is_known_column(string column) {
        ensure_init();
        foreach (Column c in columns) {
            if (c.name == column) return true;
        }
        return false;
    }

    public void create_table_at_version(long version) {
        ensure_init();
        string sql = @"CREATE TABLE IF NOT EXISTS $name (";
        for (int i = 0; i < columns.length; i++) {
            Column c = columns[i];
            if (c.min_version <= version && c.max_version >= version) {
                sql += @"$(i > 0 ? "," : "") $c";
            }
        }
        sql += @"$constraints)";
        try {
            db.exec(sql);
        } catch (Error e) {
            error("Qlite Error: Create table at version");
        }
    }

    public void add_columns_for_version(long old_version, long new_version) {
        ensure_init();
        foreach (Column c in columns) {
            if (c.min_version <= new_version && c.max_version >= new_version && c.min_version > old_version) {
                try {
                    db.exec(@"ALTER TABLE $name ADD COLUMN $c");
                } catch (Error e) {
                    error("Qlite Error: Add columns for version");
                }
            }
        }
    }

    public void delete_columns_for_version(long old_version, long new_version) {
        bool column_deletion_required = false;
        string column_list = "";
        foreach (Column c in columns) {
            if (c.min_version <= new_version && c.max_version >= new_version) {
                if (column_list == "") {
                    column_list = c.name;
                } else {
                    column_list += ", " + c.name;
                }
            }
            if (!(c.min_version <= new_version && c.max_version >= new_version) && c.min_version <= old_version && c.max_version >= old_version) {
                column_deletion_required = true;
            }
        }
        if (column_deletion_required) {
            try {
                db.exec(@"ALTER TABLE $name RENAME TO _$(name)_$old_version");
                create_table_at_version(new_version);
                db.exec(@"INSERT INTO $name ($column_list) SELECT $column_list FROM _$(name)_$old_version");
                db.exec(@"DROP TABLE _$(name)_$old_version");
            } catch (Error e) {
                error("Qlite Error: Delete volumns for version change");
            }
        }
    }

    internal void post() {
        foreach (string stmt in post_statements) {
            try {
                db.exec(stmt);
            } catch (Error e) {
                error("Qlite Error: Post");
            }
        }
    }
}

}
