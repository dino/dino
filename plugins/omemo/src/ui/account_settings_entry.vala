namespace Dino.Plugins.Omemo {

public class AccountSettingsEntry : Plugins.AccountSettingsEntry {
    private Plugin plugin;

    public AccountSettingsEntry(Plugin plugin) {
        this.plugin = plugin;
    }

    public override string id { get {
        return "omemo_identity_key";
    }}

    public override string name { get {
        return "OMEMO";
    }}

    public override Plugins.AccountSettingsWidget? get_widget(WidgetType type) {
        if (type == WidgetType.GTK) {
            return new AccountSettingWidget(plugin);
        }
        return null;
    }
}

}