namespace Dino.Plugins.OpenPgp {

public class AccountSettingsEntry : Plugins.AccountSettingsEntry {

    public override string id { get {
        return "pgp_key_picker";
    }}

    public override string name { get {
        return "OpenPGP";
    }}

    public override Plugins.AccountSettingsWidget get_widget() {
        return new AccountSettingsWidget();
    }
}

}