using Gee;

namespace Dino.Plugins {

public class Registry {
    internal ArrayList<EncryptionListEntry> encryption_list_entries = new ArrayList<EncryptionListEntry>();
    internal ArrayList<AccountSettingsEntry> account_settings_entries = new ArrayList<AccountSettingsEntry>();
    internal ArrayList<ContactDetailsProvider> contact_details_entries = new ArrayList<ContactDetailsProvider>();
    internal Map<string, TextCommand> text_commands = new HashMap<string, TextCommand>();
    internal Gee.List<ConversationAdditionPopulator> conversation_addition_populators = new ArrayList<ConversationAdditionPopulator>();
    internal Gee.List<NotificationPopulator> notification_populators = new ArrayList<NotificationPopulator>();
    internal Gee.Collection<ConversationTitlebarEntry> conversation_titlebar_entries = new Gee.TreeSet<ConversationTitlebarEntry>((a, b) => {
        return (int)(a.order - b.order);
    });

    public bool register_encryption_list_entry(EncryptionListEntry entry) {
        lock(encryption_list_entries) {
            foreach(var e in encryption_list_entries) {
                if (e.encryption == entry.encryption) return false;
            }
            encryption_list_entries.add(entry);
            encryption_list_entries.sort((a,b) => b.name.collate(a.name));
            return true;
        }
    }

    public bool register_account_settings_entry(AccountSettingsEntry entry) {
        lock(account_settings_entries) {
            foreach(var e in account_settings_entries) {
                if (e.id == entry.id) return false;
            }
            account_settings_entries.add(entry);
            // TODO: Order by priority
            account_settings_entries.sort((a,b) => b.name.collate(a.name));
            return true;
        }
    }

    public bool register_contact_details_entry(ContactDetailsProvider entry) {
        lock(contact_details_entries) {
            foreach(ContactDetailsProvider e in contact_details_entries) {
                if (e.id == entry.id) return false;
            }
            contact_details_entries.add(entry);
            return true;
        }
    }

    public bool register_text_command(TextCommand cmd) {
        lock(text_commands) {
            if (text_commands.has_key(cmd.cmd)) return false;
            text_commands[cmd.cmd] = cmd;
            return true;
        }
    }

    public bool register_contact_titlebar_entry(ConversationTitlebarEntry entry) {
        lock(conversation_titlebar_entries) {
            foreach(ConversationTitlebarEntry e in conversation_titlebar_entries) {
                if (e.id == entry.id) return false;
            }
            conversation_titlebar_entries.add(entry);
            return true;
        }
    }

    public bool register_conversation_addition_populator(ConversationAdditionPopulator populator) {
        lock (conversation_addition_populators) {
            foreach(ConversationItemPopulator p in conversation_addition_populators) {
                if (p.id == populator.id) return false;
            }
            conversation_addition_populators.add(populator);
            return true;
        }
    }

    public bool register_notification_populator(NotificationPopulator populator) {
        lock (notification_populators) {
            foreach(NotificationPopulator p in notification_populators) {
                if (p.id == populator.id) return false;
            }
            notification_populators.add(populator);
            return true;
        }
    }
}

}
