using Gdk;
using Gee;
using Gtk;
using Markup;
using Gcr;

using Dino.Entities;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/certificate_pinning_dialog.ui")]
public class CertificatePinningDialog : Gtk.Dialog {

    [GtkChild] public CertificateWidget certificate_widget;
    [GtkChild] public Label info_label;
    [GtkChild] public Button pin_certificate_button;

    private Database db;
    private Account account;
    private TlsCertificate? server_certificate;
    private bool do_trust;

    construct {
        pin_certificate_button.clicked.connect(on_pin_certificate);
    }

    public CertificatePinningDialog(Database db, Account account, TlsCertificate? server_certificate, bool used_pinned_certificate) {
        Object(use_header_bar : 1);
        this.db = db;
        this.account = account;
        this.server_certificate = server_certificate;
        if (server_certificate != null) {
            Certificate gcr_certificate = new SimpleCertificate(server_certificate.certificate.data);
            certificate_widget.set_certificate(gcr_certificate);
        } else {
           info_label.label = "";
           pin_certificate_button.sensitive = false;
           return;
        }
        if (!used_pinned_certificate) {
           // only show certificate, no pinning needed
           info_label.label = "";
           pin_certificate_button.sensitive = false;
        } else if (account.certificate != null && server_certificate.is_same(account.certificate)) {
           info_label.label = _("This certificate is pinned.");
           pin_certificate_button.label = _("Remove trust");
           do_trust = false;
        } else {
           if (account.certificate != null)
               info_label.label = _("The certificate has changed.");
           else
               info_label.label = "";
           pin_certificate_button.label = _("Pin this certificate");
           do_trust = true;
        }
    }

    private void on_pin_certificate() {
        // save certificate in database
        if (do_trust)
            account.certificate = this.server_certificate;
        else
            account.certificate = null;
        // and trigger reconnect
        destroy();
    }

}

}
