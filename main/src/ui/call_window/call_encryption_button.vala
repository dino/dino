using Dino.Entities;
using Gtk;
using Pango;

public class Dino.Ui.CallEncryptionButton : MenuButton {

    private Image encryption_image = new Image.from_icon_name("", IconSize.BUTTON) { visible=true };
    private bool has_been_set = false;
    public bool controls_active { get; set; default=false; }

    public CallEncryptionButton() {
        this.opacity = 0;
        add(encryption_image);
        this.set_popover(popover);

        this.notify["controls-active"].connect(update_opacity);
    }

    public void set_icon(bool encrypted, string? icon_name) {
        if (encrypted) {
            encryption_image.set_from_icon_name(icon_name ?? "changes-prevent-symbolic", IconSize.BUTTON);
            get_style_context().remove_class("unencrypted");
        } else {
            encryption_image.set_from_icon_name(icon_name ?? "changes-allow-symbolic", IconSize.BUTTON);
            get_style_context().add_class("unencrypted");
        }
        has_been_set = true;
        update_opacity();
    }

    public void set_info(string? title, bool show_keys, Xmpp.Xep.Jingle.ContentEncryption? audio_encryption, Xmpp.Xep.Jingle.ContentEncryption? video_encryption) {
        Popover popover = new Popover(this);
        this.set_popover(popover);

        if (audio_encryption == null) {
            popover.add(new Label("This call is unencrypted.") { margin=10, visible=true } );
            return;
        }
        if (title != null && !show_keys) {
            popover.add(new Label(title) { use_markup=true, margin=10, visible=true } );
            return;
        }

        Box box = new Box(Orientation.VERTICAL, 10) { margin=10, visible=true };
        box.add(new Label("<b>%s</b>".printf(title ?? "This call is end-to-end encrypted.")) { use_markup=true, xalign=0, visible=true });

        if (video_encryption == null) {
            box.add(create_media_encryption_grid(audio_encryption));
        } else {
            box.add(new Label("<b>Audio</b>") { use_markup=true, xalign=0, visible=true });
            box.add(create_media_encryption_grid(audio_encryption));
            box.add(new Label("<b>Video</b>") { use_markup=true, xalign=0, visible=true });
            box.add(create_media_encryption_grid(video_encryption));
        }
        popover.add(box);
    }

    public void update_opacity() {
        this.opacity = controls_active && has_been_set ? 1 : 0;
    }

    private Grid create_media_encryption_grid(Xmpp.Xep.Jingle.ContentEncryption? encryption) {
        Grid ret = new Grid() { row_spacing=3, column_spacing=5, visible=true };
        if (encryption.peer_key.length > 0) {
            ret.attach(new Label("Peer call key") { xalign=0, visible=true }, 1, 2, 1, 1);
            ret.attach(new Label("<span font_family='monospace'>" + format_fingerprint(encryption.peer_key) + "</span>") { use_markup=true, max_width_chars=25, ellipsize=EllipsizeMode.MIDDLE, xalign=0, hexpand=true, visible=true }, 2, 2, 1, 1);
        }
        if (encryption.our_key.length > 0) {
            ret.attach(new Label("Your call key") { xalign=0, visible=true }, 1, 3, 1, 1);
            ret.attach(new Label("<span font_family='monospace'>" + format_fingerprint(encryption.our_key) + "</span>") { use_markup=true, max_width_chars=25, ellipsize=EllipsizeMode.MIDDLE, xalign=0, hexpand=true, visible=true }, 2, 3, 1, 1);
        }
        return ret;
    }

    private string format_fingerprint(uint8[] fingerprint) {
        var sb = new StringBuilder();
        for (int i = 0; i < fingerprint.length; i++) {
            sb.append("%02x".printf(fingerprint[i]));
            if (i < fingerprint.length - 1) {
                sb.append(":");
            }
        }
        return sb.str;
    }
}