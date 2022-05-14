using Dino.Entities;
using Gtk;
using Pango;

public class Dino.Ui.CallEncryptionButtonController : Object {

    private bool has_been_set = false;
    public bool controls_active { get; set; default=false; }

    public MenuButton button;

    public CallEncryptionButtonController(MenuButton button) {
        this.button = button;

        button.opacity = 0;
//        button.set_popover(popover);

        button.notify["controls-active"].connect(update_opacity);
    }

    public void set_icon(bool encrypted, string? icon_name) {
        if (encrypted) {
            button.icon_name = icon_name ?? "changes-prevent-symbolic";
            button.remove_css_class("unencrypted");
        } else {
            button.icon_name = icon_name ?? "changes-allow-symbolic";
            button.add_css_class("unencrypted");
        }
        has_been_set = true;
        update_opacity();
    }

    public void set_info(string? title, bool show_keys, Xmpp.Xep.Jingle.ContentEncryption? audio_encryption, Xmpp.Xep.Jingle.ContentEncryption? video_encryption) {
        Popover popover = new Popover();
        button.set_popover(popover);

        if (audio_encryption == null) {
            popover.set_child(new Label("This call is unencrypted.") );
            return;
        }
        if (title != null && !show_keys) {
            popover.set_child(new Label(title) { use_markup=true } );
            return;
        }

        Box box = new Box(Orientation.VERTICAL, 10);
        box.append(new Label("<b>%s</b>".printf(title ?? "This call is end-to-end encrypted.")) { use_markup=true, xalign=0 });

        if (video_encryption == null) {
            box.append(create_media_encryption_grid(audio_encryption));
        } else {
            box.append(new Label("<b>Audio</b>") { use_markup=true, xalign=0 });
            box.append(create_media_encryption_grid(audio_encryption));
            box.append(new Label("<b>Video</b>") { use_markup=true, xalign=0 });
            box.append(create_media_encryption_grid(video_encryption));
        }
        popover.set_child(box);
    }

    public void update_opacity() {
        button.opacity = controls_active && has_been_set ? 1 : 0;
    }

    private Grid create_media_encryption_grid(Xmpp.Xep.Jingle.ContentEncryption? encryption) {
        Grid ret = new Grid() { row_spacing=3, column_spacing=5 };
        if (encryption.peer_key.length > 0) {
            ret.attach(new Label("Peer call key") { xalign=0 }, 1, 2, 1, 1);
            ret.attach(new Label("<span font_family='monospace'>" + format_fingerprint(encryption.peer_key) + "</span>") { use_markup=true, max_width_chars=25, ellipsize=EllipsizeMode.MIDDLE, xalign=0, hexpand=true }, 2, 2, 1, 1);
        }
        if (encryption.our_key.length > 0) {
            ret.attach(new Label("Your call key") { xalign=0 }, 1, 3, 1, 1);
            ret.attach(new Label("<span font_family='monospace'>" + format_fingerprint(encryption.our_key) + "</span>") { use_markup=true, max_width_chars=25, ellipsize=EllipsizeMode.MIDDLE, xalign=0, hexpand=true }, 2, 3, 1, 1);
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