using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

class AccountComboBox : ComboBox {

    public Account? selected {
        get {
            TreeIter selected;
            if (get_active_iter(out selected)) {
                Value value;
                list_store.get_value(selected, 1, out value);
                return value as Account;
            }
            return null;
        }
        set {
            TreeIter iter;
            if (list_store.get_iter_first(out iter)) {
                int i = 0;
                do {
                    Value val;
                    list_store.get_value(iter, 1, out val);
                    if ((val as Account).equals(value)) {
                        active = i;
                        break;
                    }
                    i++;
                } while (list_store.iter_next(ref iter));
            }
        }
    }

    private StreamInteractor? stream_interactor;
    private Gtk.ListStore list_store = new Gtk.ListStore(2, typeof(string), typeof(Account));

    public void initialize(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        CellRendererText renderer = new Gtk.CellRendererText();
        pack_start(renderer, true);
        add_attribute(renderer, "text", 0);

        TreeIter iter;
        foreach (Account account in stream_interactor.get_accounts()) {
            list_store.append(out iter);
            list_store.set(iter, 0, account.bare_jid.to_string(), 1, account);
        }
        set_model(list_store);
        active = 0;
    }
}

}