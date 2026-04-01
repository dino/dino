using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

public class Dino.Ui.ViewModel.ConversationDetails : Object {
    public signal void pin_changed();
    public signal void block_changed(BlockState action);
    public signal void notification_flipped();
    public signal void notification_changed(NotificationSetting setting);

    public enum BlockState {
        USER,
        DOMAIN,
        UNBLOCK
    }

    public enum NotificationOptions {
        ON_OFF,
        ON_HIGHLIGHT_OFF
    }

    public enum NotificationSetting {
        DEFAULT,
        ON,
        HIGHLIGHT,
        OFF
    }

    public ViewModel.CompatAvatarPictureModel avatar { get; set; }
    public string name { get; set; }
    public bool pinned { get; set; }

    public NotificationSetting notification { get; set; }
    public NotificationOptions notification_options { get; set; }
    public bool notification_is_default { get; set; }

    public bool show_blocked { get; set; }
    public BlockState blocked { get; set; }

    public GLib.ListStore about_rows = new GLib.ListStore(typeof(PreferencesRow.Any));
    public string? account_jid { get; set; }

    public GLib.ListStore settings_rows = new GLib.ListStore(typeof(PreferencesRow.Any));
    public GLib.ListStore room_configuration_rows { get; set; }
    public MapListModel members = new MapListModel(null, null);
    public SortListModel members_sorted = new SortListModel(null, new MucMemberSorter());

    construct {
        members = new MapListModel(members_sorted, null);
    }
}

public class MucMemberSorter : Sorter {

    public override Gtk.Ordering compare(GLib.Object? item1, GLib.Object? item2) {
        var member_list_row1 = (Dino.Ui.Model.ConferenceMember) item1;
        var member_list_row2 = (Dino.Ui.Model.ConferenceMember) item2;
        var test = new Xmpp.Xep.Muc.Affiliation[] { OWNER, ADMIN, MEMBER };
        var affiliation_ordering = new ArrayList<Xmpp.Xep.Muc.Affiliation>.wrap(test);

        var affiliation_sorting = affiliation_ordering.index_of(member_list_row1.affiliation) - affiliation_ordering.index_of(member_list_row2.affiliation);
        if (affiliation_sorting == 0) {
            return Ordering.from_cmpfunc(member_list_row1.name.collate(member_list_row2.name));
        }

        return Ordering.from_cmpfunc(affiliation_sorting);
    }

    public override Gtk.SorterOrder get_order() {
        return SorterOrder.TOTAL;
    }
}

//public class Dino.Ui.ViewModel.ConferenceDetails : Dino.Ui.ViewModel.ConversationDetails {
//    public static
//}

public class Dino.Ui.Model.ConversationDetails : Object {
    public Conversation conversation { get; set; }
    public Dino.Model.ConversationDisplayName display_name { get; set; }
    public DataForms.DataForm? data_form { get; set; }
    public string? data_form_bak;
    public bool blocked { get; set; }
    public bool domain_blocked { get; set; }

    public GLib.ListStore members = new GLib.ListStore(typeof(Ui.Model.ConferenceMember));

    public void populate(StreamInteractor stream_interactor, Conversation conversation) {
        Ui.ConversationDetails.populate_dialog(this, conversation, stream_interactor);

        if (conversation.type_ == GROUPCHAT) {
            Gee.List<Jid>? occupants = stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(conversation.counterpart, conversation.account);
            if (occupants != null) {
                foreach (Jid occupant in occupants) {
                    var affiliation = stream_interactor.get_module(MucManager.IDENTITY).get_affiliation(conversation.counterpart, occupant, conversation.account);
                    members.append(new Dino.Ui.Model.ConferenceMember() {
                        name = occupant.to_string(),
                        jid = occupant,
                        affiliation = affiliation
                    });
                }
            }
        }
    }
}

public class Dino.Ui.Model.ConferenceMember : Object {
    public string name { get; set; }
    public Jid jid { get; set; }
    public Xmpp.Xep.Muc.Affiliation affiliation { get; set; }
}

public class Dino.Ui.ViewModel.ConferenceMemberListRow : Object {
    public ViewModel.CompatAvatarPictureModel avatar { get; set; }
    public string name { get; set; }
    public string jid { get; set; }
    public Xmpp.Xep.Muc.Affiliation affiliation { get; set; }
    public string? affiliation_str { get; set; }

    construct {
        this.bind_property("affiliation", this, "affiliation-str", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, (_, from_value, ref to_value) => {
            to_value = affiliation_to_str((Xmpp.Xep.Muc.Affiliation) from_value);
            return true;
        });
    }

    private string? affiliation_to_str(Xmpp.Xep.Muc.Affiliation affiliation) {
        switch (affiliation) {
            case OWNER: return _("Owner");
            case ADMIN: return _("Admin");
            case MEMBER: return _("Member");
            default: return null;
        }
    }
}