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
        if (Path.get_dirname(exec_path).contains("dino") || Path.get_dirname(exec_path) == "." || Path.get_dirname(exec_path).contains("build")) {
            string exec_locale = Path.build_filename(Path.get_dirname(exec_path), "locale");
            if (FileUtils.test(Path.build_filename(exec_locale, "en", "LC_MESSAGES", gettext_package + ".mo"), FileTest.IS_REGULAR)) {
                locale_dir = exec_locale;
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
            if (Path.get_dirname(exec_path).contains("dino") || Path.get_dirname(exec_path) == "." || Path.get_dirname(exec_path).contains("build")) {
                search_paths += Path.build_filename(Path.get_dirname(exec_path), "plugins");
            }
            if (Path.get_basename(Path.get_dirname(exec_path)) == "bin") {
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

}
