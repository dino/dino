using Gee;
using Xmpp;

namespace Dino {

private extern const string SYSTEM_LIBDIR_NAME;
private extern const string SYSTEM_PLUGIN_DIR;

public class SearchPathGenerator {

    public string? exec_path { get; private set; }

    public SearchPathGenerator(string? exec_path) {
        this.exec_path = exec_path;
    }

    public string get_locale_path(string gettext_package, string locale_install_dir) {
        string? locale_dir = null;
        string dirname = Path.get_dirname(exec_path);
        // Does our environment look like a CMake build dir?
        if (dirname.contains("dino") || dirname == "." || dirname.contains("build")) {
            string exec_locale = Path.build_filename(dirname, "locale");
            if (FileUtils.test(Path.build_filename(exec_locale, "en", "LC_MESSAGES", gettext_package + ".mo"), FileTest.IS_REGULAR)) {
                locale_dir = exec_locale;
            }
        }
        // Does our environment look like a meson build dir?
        if (dirname == "." || Path.get_basename(dirname) == "main") {
            if (gettext_package == "dino") {
                string exec_locale = Path.build_filename(dirname, "po");
                if (FileUtils.test(Path.build_filename(exec_locale, "en", "LC_MESSAGES", gettext_package + ".mo"), FileTest.IS_REGULAR)) {
                    locale_dir = exec_locale;
                }
            } else if (gettext_package.has_prefix("dino-")) {
                // This is a plugin, so fetch from plugin subdir
                string exec_locale = Path.build_filename(dirname, "..", "plugins", gettext_package.substring(5), "po");
                if (FileUtils.test(Path.build_filename(exec_locale, "en", "LC_MESSAGES", gettext_package + ".mo"), FileTest.IS_REGULAR)) {
                    locale_dir = exec_locale;
                }
            }
        }
        return locale_dir ?? locale_install_dir;
    }

    public string[] get_plugin_paths() {
        string[] search_paths = new string[0];
        if (Environment.get_variable("DINO_PLUGIN_DIR") != null) {
            search_paths += Environment.get_variable("DINO_PLUGIN_DIR");
        }
        search_paths += Path.build_filename(Environment.get_home_dir(), ".local", "lib", "dino", "plugins");
        string? exec_path = this.exec_path;
        if (exec_path != null) {
            if (!exec_path.contains(Path.DIR_SEPARATOR_S)) {
                exec_path = Environment.find_program_in_path(this.exec_path);
            }
            string dirname = Path.get_dirname(exec_path);
            // Does our environment look like a CMake build dir?
            if (dirname.contains("dino") || dirname == "." || dirname.contains("build") || Path.get_basename(dirname) == "main") {
                search_paths += Path.build_filename(Path.get_dirname(exec_path), "plugins");
            }
            // Does our environment look like a meson build dir?
            if (dirname == "." || Path.get_basename(dirname) == "main") {
                try {
                    Dir plugin_dir = Dir.open(Path.build_path(Path.DIR_SEPARATOR_S, dirname, "..", "plugins"));
                    string? entry = null;
                    while ((entry = plugin_dir.read_name()) != null) {
                        string plugin_subdir = Path.build_path(Path.DIR_SEPARATOR_S, dirname, "..", "plugins", entry);
                        try {
                            Dir.open(plugin_subdir);
                            search_paths += plugin_subdir;
                        } catch (FileError e) {
                            // ignore
                        }
                    }
                } catch (FileError e) {
                    // ignore
                }
            }
            if (Path.get_basename(dirname) == "bin") {
                search_paths += Path.build_filename(Path.get_dirname(Path.get_dirname(exec_path)), SYSTEM_LIBDIR_NAME, "dino", "plugins");
            }
        }
        search_paths += SYSTEM_PLUGIN_DIR;
        return search_paths;
    }
}

public static string get_storage_dir() {
    return Path.build_filename(Environment.get_user_data_dir(), "dino");
}

public static string get_cache_dir() {
    return Path.build_filename(Environment.get_user_cache_dir(), "dino");
}

[CCode (cname = "dino_gettext", cheader_filename = "dino_i18n.h")]
public static extern unowned string _(string s);

[CCode (cname = "dino_ngettext", cheader_filename = "dino_i18n.h")]
public static extern unowned string n(string msgid, string plural, ulong number);

[CCode (cname = "bindtextdomain", cheader_filename = "libintl.h")]
private static extern unowned string? bindtextdomain(string domainname, string? dirname);

[CCode (cname = "bind_textdomain_codeset", cheader_filename = "libintl.h")]
private static extern unowned string? bind_textdomain_codeset(string domainname, string? codeset);

public static void internationalize(string gettext_package, string locales_dir) {
    Intl.bind_textdomain_codeset(gettext_package, "UTF-8");
    Intl.bindtextdomain(gettext_package, locales_dir);
}

public static async HashMap<ChecksumType, string> compute_file_hashes(File file, Gee.List<ChecksumType> checksum_types) {
    var checksums = new Checksum[checksum_types.size];

    for (int i = 0; i < checksum_types.size; i++) {
        checksums[i] = new Checksum(checksum_types.get(i));
    }

    FileInputStream stream = yield file.read_async();
    uint8 fbuf[1024];
    size_t size;
    while ((size = yield stream.read_async(fbuf)) > 0) {
        for (int i = 0; i < checksum_types.size; i++) {
            checksums[i].update(fbuf, size);
        }
    }

    var ret = new HashMap<ChecksumType, string>();
    for (int i = 0; i < checksum_types.size; i++) {
        var checksum_type = checksum_types.get(i);
        uint8[] digest = new uint8[64];
        size_t length = digest.length;
        checksums[i].get_digest(digest, ref length);
        string computed_hash = GLib.Base64.encode(digest[0:length]);
        ret[checksum_type] = computed_hash;
    }
    return ret;
}

}
