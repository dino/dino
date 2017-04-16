using Sqlite;

namespace Qlite {

public abstract class StatementBuilder {
    protected Database db;

    internal StatementBuilder(Database db) {
        this.db = db;
    }

    internal abstract Statement prepare() throws DatabaseError;

    internal abstract class AbstractField<T> {
        public T value;
        public Column<T>? column;

        public AbstractField(T value) {
            this.value = value;
        }

        internal abstract void bind(Statement stmt, int index);
    }

    internal class Field<T> : AbstractField<T> {
        public Field(Column<T> column, T value) {
            base(value);
            this.column = column;
        }

        internal override void bind(Statement stmt, int index) {
            ((!)column).bind(stmt, index, value);
        }
    }

    internal class NullField<T> : AbstractField<T> {
        public NullField(Column<T> column) {
            base(null);
            this.column = column;
        }

        internal override void bind(Statement stmt, int index) {
            stmt.bind_null(index);
        }
    }

    internal class StringField : AbstractField<string> {
        public StringField(string value) {
            base(value);
        }

        internal override void bind(Statement stmt, int index) {
            stmt.bind_text(index, value);
        }
    }
}

}