using Gee;
using Gtk;

using Xmpp;
using Xmpp.Xep.Bookmarks;
using Dino.Entities;

namespace Dino.Ui {

protected class ConferenceList : FilterableList {

    public signal void conversation_selected(Conversation? conversation);

    private StreamInteractor stream_interactor;
    private HashMap<Account, Set<Conference>> lists = new HashMap<Account, Set<Conference>>(Account.hash_func, Account.equals_func);
    private HashMap<Account, HashMap<Jid, Widget>> widgets = new HashMap<Account, HashMap<Jid, Widget>>(Account.hash_func, Account.equals_func);

    public ConferenceList(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        set_filter_func(filter);
        set_header_func(header);
        set_sort_func(sort);

        stream_interactor.get_module(MucManager.IDENTITY).bookmarks_updated.connect((account, conferences) => {
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

    private void add_conference(Account account, Conference conference) {
        if (!widgets.has_key(account)) {
            widgets[account] = new HashMap<Jid, Widget>(Jid.hash_func, Jid.equals_func);
        }
        var widget = new ConferenceListRow(stream_interactor, conference, account);
        widgets[account][conference.jid] = widget;
        add(widget);
    }

    private void remove_conference(Account account, Jid jid) {
        if (widgets.has_key(account) && widgets[account].has_key(jid)) {
            widgets[account][jid].destroy();
            widgets[account].unset(jid);
        }
    }

    public void refresh_conferences() {
        @foreach((widget) => { remove(widget); });
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

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

    private bool filter(ListBoxRow r) {
        if (r.get_type().is_a(typeof(ListRow))) {
            ListRow row = r as ListRow;
            if (filter_values != null) {
                foreach (string filter in filter_values) {
                    if (!(row.name_label.label.down().contains(filter.down()) ||
                            row.jid.to_string().down().contains(filter.down()))) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    public override int sort(ListBoxRow row1, ListBoxRow row2) {
        ListRow c1 = (row1 as ListRow);
        ListRow c2 = (row2 as ListRow);
        return c1.name_label.label.collate(c2.name_label.label);
    }
}

internal class ConferenceListRow : ListRow {

    public Conference bookmark;

    public ConferenceListRow(StreamInteractor stream_interactor, Conference bookmark, Account account) {
        this.jid = bookmark.jid;
        this.account = account;
        this.bookmark = bookmark;

        name_label.label = bookmark.name != null && bookmark.name != "" ? bookmark.name : bookmark.jid.to_string();
        if (stream_interactor.get_accounts().size > 1) {
            via_label.label = "via " + account.bare_jid.to_string();
        } else if (bookmark.name != null && bookmark.name != bookmark.jid.to_string()) {
            via_label.label = bookmark.jid.to_string();
        } else {
            via_label.visible = false;
        }

        image.set_jid(stream_interactor, jid, account);
    }
}

}
