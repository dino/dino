using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ChatInput {

[GtkTemplate (ui = "/im/dino/Dino/chat_input.ui")]
public class View : Box {

    public signal void file_removed(File file);

    public string text {
        owned get { return chat_text_view.text_view.buffer.text; }
        set { chat_text_view.text_view.buffer.text = value; }
    }

    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    private HashMap<File, Widget> file_widgets = new HashMap<File, Widget>();

    [GtkChild] public unowned Box quote_box;
    [GtkChild] public unowned Box file_box;
    [GtkChild] public unowned ChatTextView chat_text_view;
    [GtkChild] public unowned Button file_button;
    [GtkChild] public unowned MenuButton emoji_button;
    [GtkChild] public unowned MenuButton encryption_button;
    [GtkChild] public unowned Button send_button;
    [GtkChild] public unowned Separator file_separator;
    [GtkChild] public unowned Label chat_input_status;
    [GtkChild] public unowned Box unavailable_box;
    [GtkChild] public unowned Image unavailable_icon;
    [GtkChild] public unowned Label unavailable_label;

    public EncryptionButton encryption_widget;

    private bool is_dnd = false;
    private bool is_night = false;

    public View init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        stream_interactor.get_module(PresenceManager.IDENTITY).show_received.connect(on_show_received);

        encryption_widget = new EncryptionButton(stream_interactor, encryption_button);

        EmojiChooser chooser = new EmojiChooser();
        chooser.emoji_picked.connect((emoji) => {
            chat_text_view.text_view.buffer.insert_at_cursor(emoji, emoji.data.length);
        });
        chooser.closed.connect(do_focus);

        emoji_button.set_popover(chooser);

        file_button.tooltip_text = Util.string_if_tooltips_active(_("Send a file"));

        return this;
    }

    public void add_file(File file) {
        FileInfo file_info;
        try {
            file_info = file.query_info("*", FileQueryInfoFlags.NONE);
        } catch (Error e) {
            warning("Failed querying info for file %s", file.get_path());
            return;
        }
        var content_type = new Xmpp.FileContentType.from_file_info(file_info);

        bool is_image = Dino.Util.is_pixbuf_supported_content_type(content_type);

        Widget? widget = null;
        if (is_image) {
            var picture = new FixedRatioPicture() {
                file = file,
                height_request = 64,
                width_request = 64,
                content_fit = ContentFit.COVER,
                halign = Align.START,
                margin_top = 8,
                margin_end = 8,
                margin_bottom = 4
            };
            picture.add_css_class("image-round-corners");

            widget = picture;
        } else {
            FileInputWidget file_widget = new FileInputWidget() { margin_top = 8, margin_end = 8, margin_bottom = 4 };
            file_widget.set_info(file_info, content_type);
            widget = file_widget;
        }

        Button remove_button = new Button.from_icon_name("dino-window-close-symbolic") { halign=Align.END, valign=Align.START };
        remove_button.add_css_class("file-remove-button");
        remove_button.add_css_class("circular");
        remove_button.add_css_class("opaque");

        remove_button.clicked.connect(() => {
            this.file_removed(file);
        });

        Overlay overlay = new Overlay() { margin_end = 2, halign = Align.START, valign = Align.CENTER };
        overlay.add_css_class("file-share-wrap");
        overlay.add_overlay(remove_button);
        overlay.set_child(widget);

        file_box.append(overlay);

        file_widgets[file] = overlay;
    }

    public void remove_file(File file) {
        Widget? file_widget = file_widgets[file];

        if (file_widget == null) {
            warning("Trying to remove file that doesn't have a widget");
            return;
        }

        file_box.remove(file_widget);
        file_widgets.unset(file);
    }

    public void set_file_upload_active(bool active) {
        file_button.visible = active;
        file_separator.visible = active;
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;

        update_unavailable_message();

        do_focus();
    }

    private void on_show_received(Jid jid, Account account) {
        if (this.conversation.type_ == Conversation.Type.CHAT && this.conversation.counterpart.equals_bare(jid)) {
            update_unavailable_message();
        }
    }

    private void update_unavailable_message() {
        if (conversation.type_ != Conversation.Type.CHAT) {
            is_dnd = false;
            is_night = false;
            set_unavailable_message(null, null);
        } else {
            PresenceManager presence_manager = stream_interactor.get_module(PresenceManager.IDENTITY);
            Gee.List<Jid>? full_jids = presence_manager.get_full_jids(conversation.counterpart, conversation.account);
            if (full_jids != null) {
                foreach (Jid full_jid in full_jids) {
                    if (presence_manager.get_last_show(full_jid, conversation.account) == Presence.Stanza.SHOW_DND) {
                        if (update_utc_offset_minutes_timeout != 0) {
                            Source.remove(update_utc_offset_minutes_timeout);
                            update_utc_offset_minutes_timeout = 0;
                        }
                        is_dnd = true;
                        set_unavailable_message(Markup.printf_escaped(_("%s has <b>paused their notifications</b>"), Util.get_conversation_display_name(stream_interactor, conversation)), "dino-bell-large-none-symbolic", true);
                        return;
                    }
                }
            }
            is_dnd = false;
            update_utc_offset_minutes();
        }
    }

    private uint update_utc_offset_minutes_timeout = 0;
    private void update_utc_offset_minutes() {
        Conversation conversation = this.conversation;
        if (update_utc_offset_minutes_timeout != 0) {
            Source.remove(update_utc_offset_minutes_timeout);
            update_utc_offset_minutes_timeout = 0;
        }
        if (conversation.type_ == Conversation.Type.CHAT) {
            stream_interactor.get_module(EntityInfo.IDENTITY).get_utc_offset_minutes_for_bare_jid.begin(conversation.account, conversation.counterpart, (_, res) => {
                set_utc_offset_minutes(conversation, stream_interactor.get_module(EntityInfo.IDENTITY).get_utc_offset_minutes_for_bare_jid.end(res));
                update_utc_offset_minutes_timeout = WeakTimeout.add_once(60000 - (int) (new DateTime.now_utc().get_seconds()*1000d), this, update_utc_offset_minutes);
            });
        }
    }

    private void set_utc_offset_minutes(Conversation conversation, int utc_offset_minutes) {
        if (this.conversation != conversation) return;
        string? display_time = null;
        if (utc_offset_minutes != int.MIN && new DateTime.now_local().get_utc_offset() / TimeSpan.MINUTE != utc_offset_minutes) {
            var datetime = new DateTime.now(new TimeZone.offset(utc_offset_minutes * 60));
            if (datetime.get_hour() >= 22 || datetime.get_hour() < 8) {
                display_time = datetime.format(Util.is_24h_format() ?
                        /* xgettext:no-c-format */ /* Time in 24h format (w/o seconds) */ _("%H∶%M") :
                        /* xgettext:no-c-format */ /* Time in 12h format (w/o seconds) */ _("%l∶%M %p"));
            }
        }
        is_night = (display_time != null);
        if (!is_dnd) {
            if (!is_night) {
                set_unavailable_message(null, null);
            } else {
                set_unavailable_message(Markup.printf_escaped(_("It's <b>%s</b> for %s"), display_time, Util.get_conversation_display_name(stream_interactor, conversation)), "dino-clock-alt-symbolic", true);
            }
        }
    }

    private void set_unavailable_message(string? message, string? icon, bool use_markup = false) {
        if (message == null) {
            unavailable_box.visible = false;
        } else {
            if (use_markup) {
                unavailable_label.set_markup(message);
            } else {
                unavailable_label.use_markup = use_markup;
                unavailable_label.label = message;
            }
            unavailable_box.visible = true;
        }
        if (icon == null) {
            unavailable_icon.opacity = 0;
        } else {
            unavailable_icon.icon_name = icon;
            unavailable_icon.opacity = 1;
        }
    }

    public void set_input_state(Plugins.InputFieldStatus.MessageType message_type) {
        switch (message_type) {
            case Plugins.InputFieldStatus.MessageType.NONE:
                this.remove_css_class("dino-input-warning");
                this.remove_css_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.INFO:
                this.remove_css_class("dino-input-warning");
                this.remove_css_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.WARNING:
                this.add_css_class("dino-input-warning");
                this.remove_css_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.ERROR:
                this.remove_css_class("dino-input-warning");
                this.add_css_class("dino-input-error");
                break;
        }
    }

    public void highlight_state_description() {
        chat_input_status.add_css_class("input-status-highlight-once");
        Timeout.add(500, () => {
            chat_input_status.remove_css_class("input-status-highlight-once");
            return false;
        });
    }

    public void set_quoted_message(Widget quote_widget) {
        Widget? quote_box_child = quote_box.get_first_child();
        if (quote_box_child != null) quote_box.remove(quote_box_child);
        quote_box.append(quote_widget);
        quote_box.visible = true;
    }

    public void unset_quoted_message() {
        Widget? quote_box_child = quote_box.get_first_child();
        if (quote_box_child != null) quote_box.remove(quote_box_child);
        quote_box.visible = false;
    }

    public void clear_files() {
        Widget? file_child = file_box.get_first_child();
        while (file_child != null) {
            file_box.remove(file_child);
            file_child = file_box.get_first_child();
        }
    }

    public void do_focus() {
        chat_text_view.text_view.grab_focus();
    }
}
}

[GtkTemplate (ui = "/im/dino/Dino/file_input_widget.ui")]
public class Dino.Ui.FileInputWidget : Box {
    [GtkChild] public unowned Label name_label;
    [GtkChild] public unowned Label mime_label;
    [GtkChild] public unowned Image content_type_image;

    public void set_info(FileInfo file_info, Xmpp.FileContentType? content_type) {
        name_label.label = file_info.get_name();
        content_type_image.icon_name = Dino.Ui.FileDefaultWidget.get_file_icon_name(content_type);
        mime_label.label = content_type != null ? content_type.get_description() : null;
    }
}