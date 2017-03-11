using Gee;

namespace Dino.Plugins {

public class Registry {
    internal ArrayList<EncryptionListEntry> encryption_list_entries = new ArrayList<EncryptionListEntry>();

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
}

}