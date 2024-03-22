using Gee;
using Gtk;

using Xmpp;
using Xmpp.Xep.Bookmarks;
using Dino.Entities;

namespace Dino.Ui {

protected class ConferenceList {

    public signal void conversation_selected(Conversation? conversation);

    private StreamInteractor stream_interactor;

    private ListBox list_box = new ListBox();
    private HashMap<Account, Set<Conference>> lists = new HashMap<Account, Set<Conference>>(Account.hash_func, Account.equals_func);
    private HashMap<Account, HashMap<Jid, ListBoxRow>> widgets = new HashMap<Account, HashMap<Jid, ListBoxRow>>(Account.hash_func, Account.equals_func);

    ulong bookmarks_updated_handler_id = -1;

    public ConferenceList(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        bookmarks_updated_handler_id = stream_interactor.get_module(MucManager.IDENTITY).bookmarks_updated.connect((account, conferences) => {
            lists[account] = conferences;
            refresh_conferences();
        });

        foreach (Account account in stream_interactor.get_accounts()) {
            stream_interactor.get_module(MucManager.IDENTITY).get_bookmarks.begin(account, (_, res) => {
                Set<Conference>? conferences = stream_interactor.get_module(MucManager.IDENTITY).get_bookmarks.end(res);
                set_bookmarks(account, conferences);
            });
        }

        stream_interactor.get_module(MucManager.IDENTITY).conference_added.connect(add_conference);
        stream_interactor.get_module(MucManager.IDENTITY).conference_removed.connect(remove_conference);
    }

    ~ConferenceList() {
        stream_interactor.get_module(MucManager.IDENTITY).disconnect(bookmarks_updated_handler_id);
        stream_interactor.get_module(MucManager.IDENTITY).conference_added.disconnect(add_conference);
        stream_interactor.get_module(MucManager.IDENTITY).conference_removed.disconnect(remove_conference);
    }

    private void add_conference(Account account, Conference conference) {
        if (!widgets.has_key(account)) {
            widgets[account] = new HashMap<Jid, ListBoxRow>(Jid.hash_func, Jid.equals_func);
        }
        var widget = new ConferenceListRow(stream_interactor, conference, account);
        var list_box_row = new ListBoxRow();
        list_box_row.set_child(widget);
        widgets[account][conference.jid] = list_box_row;
        list_box.append(list_box_row);
    }

    private void remove_conference(Account account, Jid jid) {
        if (widgets.has_key(account) && widgets[account].has_key(jid)) {
            list_box.remove(widgets[account][jid]);
            widgets[account].unset(jid);
        }
    }

    public void refresh_conferences() {
        foreach (Account account in widgets.keys) {

            var account_widgets_cpy = new HashMap<Jid, ListBoxRow>();
            account_widgets_cpy.set_all(widgets[account]);

            foreach (Jid jid in account_widgets_cpy.keys) {
                list_box.remove(widgets[account][jid]);
            }
        }

        foreach (Account account in lists.keys) {
            foreach (Conference conference in lists[account]) {
                add_conference(account, conference);
            }
        }
    }

    private void set_bookmarks(Account account, Set<Conference>? conferences) {
        if (conferences == null) {
            lists.unset(account);
        } else {
            lists[account] = conferences;
        }
        refresh_conferences();
    }

    public ListBox get_list_box() {
        return list_box;
    }
}

internal class ConferenceListRow : ListRow {

    public Conference bookmark;

    public ConferenceListRow(StreamInteractor stream_interactor, Conference bookmark, Account account) {
        this.jid = bookmark.jid;
        this.account = account;
        this.bookmark = bookmark;

        status_dot.visible = false;
        name_label.label = bookmark.name != null && bookmark.name != "" ? bookmark.name : bookmark.jid.to_string();
        if (stream_interactor.get_accounts().size > 1) {
            via_label.label = "via " + account.bare_jid.to_string();
        } else if (bookmark.name != null && bookmark.name != bookmark.jid.to_string()) {
            via_label.label = bookmark.jid.to_string();
        } else {
            via_label.visible = false;
        }

        picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(new Conversation(jid, account, Conversation.Type.GROUPCHAT));
    }
}

}
