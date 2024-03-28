using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {

[GtkTemplate (ui = "/im/dino/Dino/occupant_list.ui")]
public class List : Box {

    public signal void conversation_selected(Conversation? conversation);
    private StreamInteractor stream_interactor;

    [GtkChild] public unowned ListBox list_box;
    [GtkChild] private unowned SearchEntry search_entry;

    private Conversation conversation;
    private string[]? filter_values;

    // List of all chat members with corresponding widgets
    private HashMap<string, Widget> rows = new HashMap<string, Widget>();
    public HashMap<Widget, ListRow> row_wrappers = new HashMap<Widget, ListRow>();

    public List(StreamInteractor stream_interactor, Conversation conversation) {
        this.stream_interactor = stream_interactor;
        list_box.set_header_func(header);
        list_box.set_sort_func(sort);
        list_box.set_filter_func(filter);
        search_entry.search_changed.connect(refilter);

        stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect(on_received_online_presence);
        stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect(on_received_offline_presence);

        initialize_for_conversation(conversation);
    }

    public bool get_status(Jid jid, Account account) {
        Gee.List<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(jid, account);

        debug("Get presence status for %s", jid.bare_jid.to_string());
        string presence_str = null;
        if (full_jids != null){
            // Iterate over all connected devices
            for (int i = 0; i < full_jids.size; i++) {
                Jid full_jid = full_jids[i];
                presence_str = stream_interactor.get_module(PresenceManager.IDENTITY).get_last_show(full_jid, account);
                switch(presence_str) {
                    case "online": {
                        // Return online status if user is online on at least one device
                        return true;
                    }
                }
            }
        } else {
            return false;
        }

        return false;
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;

        var identity = stream_interactor.get_module(MucManager.IDENTITY);
        Gee.List<Jid>? members = identity.get_all_members(conversation.counterpart, conversation.account);
        if (members != null) {
            // Add all members and their status to the list
            foreach (Jid member in members) {
                bool online = get_status(member, conversation.account);
                add_member(member, online);
            }
        }
        list_box.invalidate_filter();
    }

    private void refilter() {
        string[]? values = null;
        string str = search_entry.get_text ();
        if (str != "") values = str.split(" ");
        if (filter_values == values) return;
        filter_values = values;
        list_box.invalidate_filter();
    }

    public void add_member(Jid jid, bool online) {
        // HACK:
        // Here we track members based on their names (not jids)
        // Sometimes the same member can be referenced with different jids, for example:
        // When initializing the conversation (see initialize_for_conversation function),
        // we reference members like this:
        // test_user@test_domain (using a local part, without a resource)
        // However when updating status, we get the jid in the following format
        // local_domain@test_domain/test_user (using a resource)
        string member_name = null;
        if (jid.resourcepart != null) {
            member_name = jid.resourcepart;
        } else {
            member_name = jid.localpart;
        }

        if (member_name == null) {
            return;
        }

        if (!rows.has_key(member_name)) {
            debug("adding new member %s", jid.to_string());
            debug("local %s", jid.localpart);
            debug("domain %s", jid.domainpart);
            debug("resource %s", jid.resourcepart);

            var row_wrapper = new ListRow(stream_interactor, conversation, jid);
            var widget = row_wrapper.get_widget();

            if (online) {
                row_wrapper.set_online();
            } else {
                row_wrapper.set_offline();
            }

            row_wrappers[widget] = row_wrapper;
            rows[member_name] = widget;
            list_box.append(widget);
        }
    }

    private void on_received_offline_presence(Jid jid, Account account) {
        if (conversation != null && conversation.counterpart.equals_bare(jid) && jid.is_full()) {
            var member_name = jid.resourcepart;
            if (member_name == null) {
                return;
            }

            if (rows.has_key(member_name)) {
                row_wrappers[rows[member_name]].set_offline();
                debug("%s is now offline", jid.to_string());
            }
            list_box.invalidate_filter();
        }
    }

    private void on_received_online_presence(Jid jid, Account account) {
        if (conversation != null && conversation.counterpart.equals_bare(jid) && jid.is_full()) {
            var member_name = jid.resourcepart;
            if (member_name == null) {
                return;
            }

            if (!rows.has_key(member_name)) {
                add_member(jid, true);
            }

            row_wrappers[rows[member_name]].set_online();
            debug("%s is now online", jid.to_string());
            list_box.invalidate_filter();
        }
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        ListRow row_wrapper1 = row_wrappers[row.get_child()];
        Xmpp.Xep.Muc.Affiliation? a1 = stream_interactor.get_module(MucManager.IDENTITY).get_affiliation(conversation.counterpart, row_wrapper1.jid, row_wrapper1.conversation.account);
        if (a1 == null) return;

        if (before_row != null) {
            ListRow row_wrapper2 = row_wrappers[before_row.get_child()];
            Xmpp.Xep.Muc.Affiliation? a2 = stream_interactor.get_module(MucManager.IDENTITY).get_affiliation(conversation.counterpart, row_wrapper2.jid, row_wrapper2.conversation.account);
            if (a1 != a2) {
                row.set_header(generate_header_widget(a1, false));
            } else if (row.get_header() != null){
                row.set_header(null);
            }
        } else {
            row.set_header(generate_header_widget(a1, true));
        }
    }

    private Widget generate_header_widget(Xmpp.Xep.Muc.Affiliation affiliation, bool top) {
        string aff_str;
        switch (affiliation) {
            case Xmpp.Xep.Muc.Affiliation.OWNER:
                aff_str = _("Owner"); break;
            case Xmpp.Xep.Muc.Affiliation.ADMIN:
                aff_str = _("Admin"); break;
            case Xmpp.Xep.Muc.Affiliation.MEMBER:
                aff_str = _("Member"); break;
            default:
                aff_str = _("User"); break;
        }

        int count = 0;
        foreach (ListRow row in row_wrappers.values) {
            Xmpp.Xep.Muc.Affiliation aff = stream_interactor.get_module(MucManager.IDENTITY).get_affiliation(conversation.counterpart, row.jid, conversation.account);
            if (aff == affiliation) count++;
        }

        Label title_label = new Label("") { margin_start=10, xalign=0 };
        title_label.set_markup(@"<b>$(Markup.escape_text(aff_str))</b>");

        Label count_label = new Label(@"$count") { xalign=0, margin_end=7, hexpand=true };
        count_label.add_css_class("dim-label");

        Grid grid = new Grid() { margin_top=top?5:15, column_spacing=5, hexpand=true };
        grid.attach(title_label, 0, 0, 1, 1);
        grid.attach(count_label, 1, 0, 1, 1);
        grid.attach(new Separator(Orientation.HORIZONTAL) { hexpand=true, vexpand=true }, 0, 1, 2, 1);
        return grid;
    }

    private bool filter(ListBoxRow r) {
        ListRow row_wrapper = row_wrappers[r.get_child()];
        foreach (string filter in filter_values) {
            return row_wrapper.name_label.label.down().contains(filter.down());
        }
        return true;
    }

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        ListRow row_wrapper1 = row_wrappers[row1.get_child()];
        ListRow row_wrapper2 = row_wrappers[row2.get_child()];

        int affiliation1 = get_affiliation_ranking(stream_interactor.get_module(MucManager.IDENTITY).get_affiliation(conversation.counterpart, row_wrapper1.jid, row_wrapper1.conversation.account) ?? Xmpp.Xep.Muc.Affiliation.NONE);
        int affiliation2 = get_affiliation_ranking(stream_interactor.get_module(MucManager.IDENTITY).get_affiliation(conversation.counterpart, row_wrapper2.jid, row_wrapper2.conversation.account) ?? Xmpp.Xep.Muc.Affiliation.NONE);

        if (affiliation1 < affiliation2) return -1;
        else if (affiliation1 > affiliation2) return 1;
        else return row_wrapper1.name_label.label.collate(row_wrapper2.name_label.label);
    }

    private int get_affiliation_ranking(Xmpp.Xep.Muc.Affiliation affiliation) {
        switch (affiliation) {
            case Xmpp.Xep.Muc.Affiliation.OWNER:
                return 1;
            case Xmpp.Xep.Muc.Affiliation.ADMIN:
                return 2;
            case Xmpp.Xep.Muc.Affiliation.MEMBER:
                return 3;
            default:
                return 4;
        }
    }
}

}
