using Dino;
using Dino.Entities;
using Xmpp;
using Xmpp.Xep;

public class Dino.Ui.ViewModel.AccountDetails : Object {
    public Entities.Account account { get; set; }
    public string bare_jid { owned get { return account.bare_jid.to_string(); } }
    public CompatAvatarPictureModel avatar_model { get; set; }
    public ConnectionManager.ConnectionState connection_state { get; set; }
    public ConnectionManager.ConnectionError? connection_error { get; set; }

    public AccountDetails(Account account, StreamInteractor stream_interactor) {
        var account_conv = new Conversation(account.bare_jid, account, Conversation.Type.CHAT);

        this.account = account;
        this.avatar_model = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(account_conv);
        this.connection_state = stream_interactor.connection_manager.get_state(account);
        this.connection_error = stream_interactor.connection_manager.get_error(account);
    }
}