using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui.AddConversation.Conference {

protected class ConferenceList : FilterableList {

    public signal void conversation_selected(Conversation? conversation);

    private StreamInteractor stream_interactor;
    private HashMap<Account, ArrayList<Xep.Bookmarks.Conference>> lists = new HashMap<Account, ArrayList<Xep.Bookmarks.Conference>>();

    public ConferenceList(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        set_filter_func(filter);
        set_header_func(header);
        set_sort_func(sort);

        MucManager.get_instance(stream_interactor).bookmarks_updated.connect((account, conferences) => {
            Idle.add(() => {
                lists[account] = conferences;
                refresh_conferences();
                return false;
            });
        });

        foreach (Account account in stream_interactor.get_accounts()) {
            MucManager.get_instance(stream_interactor).get_bookmarks(account, new BookmarksListener(this, stream_interactor, account));
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

    private class BookmarksListener : Xep.Bookmarks.ConferencesRetrieveResponseListener, Object {
        ConferenceList outer;
        Account account;
        public BookmarksListener(ConferenceList outer, StreamInteractor stream_interactor, Account account) {
            this.outer = outer;
            this.account = account;
        }

        public void on_result(Core.XmppStream stream, ArrayList<Xep.Bookmarks.Conference> conferences) {
            outer.lists[account] = conferences;
            Idle.add(() => { outer.refresh_conferences(); return false; });
        }
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
        this.jid = new Jid(bookmark.jid);
        this.account = account;
        this.bookmark = bookmark;

        if (bookmark.name != "" && bookmark.name != bookmark.jid) {
            name_label.label = bookmark.name;
            via_label.label = bookmark.jid;
        } else {
            name_label.label = bookmark.jid;
            via_label.visible = false;
        }
        image.set_from_pixbuf((new AvatarGenerator(35, 35)).set_stateless(true).draw_jid(stream_interactor, jid, account));
    }
}

}