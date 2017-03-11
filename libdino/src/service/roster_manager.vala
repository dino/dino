using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {
    public class RosterManager : StreamInteractionModule, Object {
        public const string id = "roster_manager";

        public signal void removed_roster_item(Account account, Jid jid, Roster.Item roster_item);
        public signal void updated_roster_item(Account account, Jid jid, Roster.Item roster_item);

        private StreamInteractor stream_interactor;

        public static void start(StreamInteractor stream_interactor) {
            RosterManager m = new RosterManager(stream_interactor);
            stream_interactor.add_module(m);
        }

        public RosterManager(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
            stream_interactor.account_added.connect(on_account_added);
        }

        public ArrayList<Roster.Item> get_roster(Account account) {
            Core.XmppStream? stream = stream_interactor.get_stream(account);
            ArrayList<Roster.Item> ret = new ArrayList<Roster.Item>();
            if (stream != null) {
                ret.add_all(Xmpp.Roster.Flag.get_flag(stream).get_roster());
            }
            return ret;
        }

        public Roster.Item? get_roster_item(Account account, Jid jid) {
            Core.XmppStream? stream = stream_interactor.get_stream(account);
            if (stream != null) {
                return Xmpp.Roster.Flag.get_flag(stream).get_item(jid.bare_jid.to_string());
            }
            return null;
        }

        public void remove_jid(Account account, Jid jid) {
            Core.XmppStream? stream = stream_interactor.get_stream(account);
            if (stream != null) stream.get_module(Xmpp.Roster.Module.IDENTITY).remove_jid(stream, jid.bare_jid.to_string());
        }

        public void add_jid(Account account, Jid jid, string? handle) {
            Core.XmppStream? stream = stream_interactor.get_stream(account);
            if (stream != null) stream.get_module(Xmpp.Roster.Module.IDENTITY).add_jid(stream, jid.bare_jid.to_string(), handle);
        }

        public static RosterManager? get_instance(StreamInteractor stream_interactor) {
            return (RosterManager) stream_interactor.get_module(id);
        }

        internal string get_id() {
            return id;
        }

        private void on_account_added(Account account) {
            stream_interactor.module_manager.get_module(account, Roster.Module.IDENTITY).received_roster.connect( (stream, roster) => {
                on_roster_received(account, roster);
            });
            stream_interactor.module_manager.get_module(account, Roster.Module.IDENTITY).item_removed.connect( (stream, roster_item) => {
                removed_roster_item(account, new Jid(roster_item.jid), roster_item);
            });
            stream_interactor.module_manager.get_module(account, Roster.Module.IDENTITY).item_updated.connect( (stream, roster_item) => {
                on_roster_item_updated(account, roster_item);
            });
        }

        private void on_roster_received(Account account, Collection<Roster.Item> roster_items) {
            foreach (Roster.Item roster_item in roster_items) {
                on_roster_item_updated(account, roster_item);
            }
        }

        private void on_roster_item_updated(Account account, Roster.Item roster_item) {
            updated_roster_item(account, new Jid(roster_item.jid), roster_item);
        }
    }
}