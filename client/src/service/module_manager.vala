using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

public class ModuleManager {

    public HashMap<Account, Tls.Module> tls_modules = new HashMap<Account, Tls.Module>();
    public HashMap<Account, PlainSasl.Module> plain_sasl_modules = new HashMap<Account, PlainSasl.Module>();
    public HashMap<Account, Bind.Module> bind_modules = new HashMap<Account, Bind.Module>();
    public HashMap<Account, Roster.Module> roster_modules = new HashMap<Account, Roster.Module>();
    public HashMap<Account, Xep.ServiceDiscovery.Module> service_discovery_modules = new HashMap<Account, Xep.ServiceDiscovery.Module>();
    public HashMap<Account, Xep.PrivateXmlStorage.Module> private_xmp_storage_modules = new HashMap<Account, Xep.PrivateXmlStorage.Module>();
    public HashMap<Account, Xep.Bookmarks.Module> bookmarks_module = new HashMap<Account, Xep.Bookmarks.Module>();
    public HashMap<Account, Presence.Module> presence_modules = new HashMap<Account, Presence.Module>();
    public HashMap<Account, Xmpp.Message.Module> message_modules = new HashMap<Account, Xmpp.Message.Module>();
    public HashMap<Account, Xep.MessageCarbons.Module> message_carbons_modules = new HashMap<Account, Xep.MessageCarbons.Module>();
    public HashMap<Account, Xep.Muc.Module> muc_modules = new HashMap<Account, Xep.Muc.Module>();
    public HashMap<Account, Xep.Pgp.Module> pgp_modules = new HashMap<Account, Xep.Pgp.Module>();
    public HashMap<Account, Xep.Pubsub.Module> pubsub_modules = new HashMap<Account, Xep.Pubsub.Module>();
    public HashMap<Account, Xep.EntityCapabilities.Module> entity_capabilities_modules = new HashMap<Account, Xep.EntityCapabilities.Module>();
    public HashMap<Account, Xep.UserAvatars.Module> user_avatars_modules = new HashMap<Account, Xep.UserAvatars.Module>();
    public HashMap<Account, Xep.VCard.Module> vcard_modules = new HashMap<Account, Xep.VCard.Module>();
    public HashMap<Account, Xep.MessageDeliveryReceipts.Module> message_delivery_receipts_modules = new HashMap<Account, Xep.MessageDeliveryReceipts.Module>();
    public HashMap<Account, Xep.ChatStateNotifications.Module> chat_state_notifications_modules = new HashMap<Account, Xep.ChatStateNotifications.Module>();
    public HashMap<Account, Xep.ChatMarkers.Module> chat_markers_modules = new HashMap<Account, Xep.ChatMarkers.Module>();
    public HashMap<Account, Xep.Ping.Module> ping_modules = new HashMap<Account, Xep.Ping.Module>();
    public HashMap<Account, Xep.DelayedDelivery.Module> delayed_delivery_module = new HashMap<Account, Xep.DelayedDelivery.Module>();
    public HashMap<Account, StreamError.Module> stream_error_modules = new HashMap<Account, StreamError.Module>();

    private AvatarStorage avatar_storage = new AvatarStorage("./");
    private EntityCapabilitiesStorage entity_capabilities_storage;

    public ModuleManager(Database db) {
        entity_capabilities_storage = new EntityCapabilitiesStorage(db);
    }

    public ArrayList<Core.XmppStreamModule> get_modules(Account account, string? resource = null) {
        ArrayList<Core.XmppStreamModule> modules = new ArrayList<Core.XmppStreamModule>();

        if (!tls_modules.has_key(account)) add_account(account);

        modules.add(tls_modules[account]);
        modules.add(plain_sasl_modules[account]);
        modules.add(new Bind.Module(resource == null ? account.resourcepart : resource));
        modules.add(roster_modules[account]);
        modules.add(service_discovery_modules[account]);
        modules.add(private_xmp_storage_modules[account]);
        modules.add(bookmarks_module[account]);
        modules.add(presence_modules[account]);
        modules.add(message_modules[account]);
        modules.add(message_carbons_modules[account]);
        modules.add(muc_modules[account]);
        modules.add(pgp_modules[account]);
        modules.add(pubsub_modules[account]);
        modules.add(entity_capabilities_modules[account]);
        modules.add(user_avatars_modules[account]);
        modules.add(vcard_modules[account]);
        modules.add(message_delivery_receipts_modules[account]);
        modules.add(chat_state_notifications_modules[account]);
        modules.add(chat_markers_modules[account]);
        modules.add(ping_modules[account]);
        modules.add(delayed_delivery_module[account]);
        modules.add(stream_error_modules[account]);
        return modules;
    }

    public void add_account(Account account) {
        tls_modules[account] = new Tls.Module();
        plain_sasl_modules[account] = new PlainSasl.Module(account.bare_jid.to_string(), account.password);
        bind_modules[account] = new Bind.Module(account.resourcepart);
        roster_modules[account] = new Roster.Module();
        service_discovery_modules[account] = new Xep.ServiceDiscovery.Module.with_identity("client", "pc");
        private_xmp_storage_modules[account] = new Xep.PrivateXmlStorage.Module();
        bookmarks_module[account] = new Xep.Bookmarks.Module();
        presence_modules[account] = new Presence.Module();
        message_modules[account] = new Xmpp.Message.Module();
        message_carbons_modules[account] = new Xep.MessageCarbons.Module();
        muc_modules[account] = new Xep.Muc.Module();
        pgp_modules[account] = new Xep.Pgp.Module();
        pubsub_modules[account] = new Xep.Pubsub.Module();
        entity_capabilities_modules[account] = new Xep.EntityCapabilities.Module(entity_capabilities_storage);
        user_avatars_modules[account] = new Xep.UserAvatars.Module(avatar_storage);
        vcard_modules[account] = new Xep.VCard.Module(avatar_storage);
        message_delivery_receipts_modules[account] = new Xep.MessageDeliveryReceipts.Module();
        chat_state_notifications_modules[account] = new Xep.ChatStateNotifications.Module();
        chat_markers_modules[account] = new Xep.ChatMarkers.Module();
        ping_modules[account] = new Xep.Ping.Module();
        delayed_delivery_module[account] = new Xep.DelayedDelivery.Module();
        stream_error_modules[account] = new StreamError.Module();
    }
}

}