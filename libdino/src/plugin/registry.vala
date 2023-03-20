using Gee;

namespace Dino.Plugins {

public class Registry {
    public HashMap<Entities.Encryption, EncryptionListEntry> encryption_list_entries = new HashMap<Entities.Encryption, EncryptionListEntry>();
    public HashMap<string, CallEncryptionEntry> call_encryption_entries = new HashMap<string, CallEncryptionEntry>();
    public ArrayList<AccountSettingsEntry> account_settings_entries = new ArrayList<AccountSettingsEntry>();
    public ArrayList<ContactDetailsProvider> contact_details_entries = new ArrayList<ContactDetailsProvider>();
    public Map<string, TextCommand> text_commands = new HashMap<string, TextCommand>();
    public Gee.List<ConversationAdditionPopulator> conversation_addition_populators = new ArrayList<ConversationAdditionPopulator>();
    public Gee.List<NotificationPopulator> notification_populators = new ArrayList<NotificationPopulator>();
    public Gee.Collection<ConversationTitlebarEntry> conversation_titlebar_entries = new Gee.TreeSet<ConversationTitlebarEntry>((a, b) => {
        return (int)(a.order - b.order);
    });
    public VideoCallPlugin? video_call_plugin;

    public bool register_encryption_list_entry(EncryptionListEntry entry) {
        lock(encryption_list_entries) {
            if (encryption_list_entries.has_key(entry.encryption)) return false;

            encryption_list_entries[entry.encryption] = entry;
            return true;
        }
    }

    public bool register_call_entryption_entry(string ns, CallEncryptionEntry entry) {
        lock (call_encryption_entries) {
            call_encryption_entries[ns] = entry;
        }
        return true;
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
