using Gee;

namespace Dino.Plugins {

public class Registry {
    internal ArrayList<EncryptionListEntry> encryption_list_entries = new ArrayList<EncryptionListEntry>();
    internal ArrayList<AccountSettingsEntry> account_settings_entries = new ArrayList<AccountSettingsEntry>();
    internal ArrayList<ContactDetailsProvider> contact_details_entries = new ArrayList<ContactDetailsProvider>();
    internal Map<string, TextCommand> text_commands = new HashMap<string, TextCommand>();
    internal Gee.Collection<ConversationTitlebarEntry> conversation_titlebar_entries = new Gee.TreeSet<ConversationTitlebarEntry>((a, b) => {
        if (a.order < b.order) {
            return -1;
        } else if (a.order > b.order) {
            return 1;
        } else {
            return 0;
        }
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
}

}
