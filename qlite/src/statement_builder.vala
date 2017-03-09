using Sqlite;

namespace Qlite {

public abstract class StatementBuilder {
    protected Database db;

    public StatementBuilder(Database db) {
        this.db = db;
    }

    public abstract Statement prepare() throws DatabaseError;

    protected class Field<T> {
        public T value;
        public Column<T>? column;

        public Field(Column<T>? column, T value) {
            this.column = column;
            this.value = value;
        }

        public virtual void bind(Statement stmt, int index) {
            if (column != null) {
                column.bind(stmt, index, value);
            }
        }
    }

    protected class NullField<T> : Field<T> {
        public NullField(Column<T>? column) {
            base(column, null);
        }

        public override void bind(Statement stmt, int index) {
            stmt.bind_null(index);
        }
    }

    protected class StringField : Field<string> {
        public StringField(string value) {
            base(null, value);
        }

        public override void bind(Statement stmt, int index) {
            stmt.bind_text(index, value);
        }
    }
}

}