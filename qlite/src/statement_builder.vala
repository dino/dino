using Sqlite;

namespace Qlite {

public abstract class StatementBuilder {
    protected Database db;

    internal StatementBuilder(Database db) {
        this.db = db;
    }

    internal abstract Statement prepare() throws DatabaseError;

    internal class Field<T> {
        public T value;
        public Column<T>? column;

        public Field(Column<T>? column, T value) {
            this.column = column;
            this.value = value;
        }

        internal virtual void bind(Statement stmt, int index) {
            if (column != null) {
                column.bind(stmt, index, value);
            }
        }
    }

    internal class NullField<T> : Field<T> {
        public NullField(Column<T>? column) {
            base(column, null);
        }

        internal override void bind(Statement stmt, int index) {
            stmt.bind_null(index);
        }
    }

    internal class StringField : Field<string> {
        public StringField(string value) {
            base(null, value);
        }

        internal override void bind(Statement stmt, int index) {
            stmt.bind_text(index, value);
        }
    }
}

}