using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui {

protected class ConferenceList : FilterableList {

    public signal void conversation_selected(Conversation? conversation);

    private StreamInteractor stream_interactor;
    private HashMap<Account, Gee.List<Xep.Bookmarks.Conference>> lists = new HashMap<Account, Gee.List<Xep.Bookmarks.Conference>>();

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
            stream_interactor.get_module(MucManager.IDENTITY).get_bookmarks(account, (stream, conferences) => { on_conference_bookmarks_received(stream, account, conferences); });
        }
    }

    public void refresh_conferences() {
        @foreach((widget) => { remove(widget); });
        foreach (Account account in lists.keys) {
            foreach (Xep.Bookmarks.Conference conference in lists[account]) {
                add(new ConferenceListRow(stream_interactor, conference, account));
            }
        }
    }

    private void on_conference_bookmarks_received(XmppStream stream, Account account, Gee.List<Xep.Bookmarks.Conference>? conferences) {
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

    public Xep.Bookmarks.Conference bookmark;

    public ConferenceListRow(StreamInteractor stream_interactor, Xep.Bookmarks.Conference bookmark, Account account) {
        this.jid = bookmark.jid;
        this.account = account;
        this.bookmark = bookmark;

        name_label.label = bookmark.name ?? bookmark.jid.to_string();
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
