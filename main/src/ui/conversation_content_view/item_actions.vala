using Dino.Entities;
using Gtk;

namespace Dino.Ui {
    public Plugins.MessageAction get_reaction_action(ContentItem content_item, Conversation conversation, StreamInteractor stream_interactor) {
        Plugins.MessageAction action = new Plugins.MessageAction();
        action.name = "reaction";
        action.icon_name = "dino-emoticon-add-symbolic";
        action.tooltip = _("Add reaction");

        action.callback = (variant) => {
            string emoji = variant.get_string();
            stream_interactor.get_module(Reactions.IDENTITY).add_reaction(conversation, content_item, emoji);
        };

        // Disable the button if reaction aren't possible.
        bool supports_reactions = stream_interactor.get_module(Reactions.IDENTITY).conversation_supports_reactions(conversation);
        string? message_id = stream_interactor.get_module(ContentItemStore.IDENTITY).get_message_id_for_content_item(conversation, content_item);

        if (!supports_reactions) {
            action.tooltip = _("This conversation does not support reactions.");
            action.sensitive = false;
        } else if (message_id == null) {
            action.tooltip = "This message does not support reactions.";
            action.sensitive = false;
        }
        return action;
    }

    public Plugins.MessageAction get_reply_action(ContentItem content_item, Conversation conversation, StreamInteractor stream_interactor) {
        Plugins.MessageAction action = new Plugins.MessageAction();
        action.name = "reply";
        action.icon_name = "mail-reply-sender-symbolic";
        action.tooltip = _("Reply");
        action.callback = () => {
            GLib.Application.get_default().activate_action("quote", new GLib.Variant.tuple(new GLib.Variant[] { new GLib.Variant.int32(conversation.id), new GLib.Variant.int32(content_item.id) }));
        };

        // Disable the button if replies aren't possible.
        string? message_id = stream_interactor.get_module(ContentItemStore.IDENTITY).get_message_id_for_content_item(conversation, content_item);
        if (message_id == null) {
            action.sensitive = false;
            if (conversation.type_.is_muc_semantic()) {
                action.tooltip = _("This conversation does not support replies.");
            } else {
                action.tooltip = "This message does not support replies.";
            }
        }
        return action;
    }

    public Plugins.MessageAction? get_delete_action(ContentItem content_item, Conversation conversation, StreamInteractor stream_interactor) {
        bool is_deletable = stream_interactor.get_module(MessageDeletion.IDENTITY).is_deletable(conversation, content_item);
        if (!is_deletable) return null;

        bool can_delete_for_everyone = stream_interactor.get_module(MessageDeletion.IDENTITY).can_delete_for_everyone(conversation, content_item);

        Plugins.MessageAction action = new Plugins.MessageAction();
        action.name = "delete";
        action.icon_name = "user-trash-symbolic";
        action.tooltip = _("Delete message");
        action.shortcut_action = false;
        action.callback = () => {
            Adw.AlertDialog dialog = new Adw.AlertDialog(_("Delete message"), null) { content_width = 350, follows_content_size = false };
            if (can_delete_for_everyone) {
                CheckButton check_button = new CheckButton() { label="Delete for everyone", active=true };

                Box extra_child = new Box(Orientation.VERTICAL, 8);
                extra_child.append(new Label("Would you like to remove this message for everyone or just for yourself?") { xalign=0, use_markup=true, wrap=true });
                extra_child.append(new Label("The message will only be deleted for others <b>if their app supports it</b>!") { xalign=0, use_markup=true, wrap=true });
                extra_child.append(check_button);
                dialog.extra_child = extra_child;

                check_button.toggled.connect(() => {
                    dialog.remove_response("delete");
                    dialog.remove_response("cancel");
                    if (check_button.active) {
                        dialog.add_response("delete", "Delete for everyone");
                    } else {
                        dialog.add_response("delete", "Only delete for yourself");
                    }
                    dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
                    dialog.add_response("cancel", "Cancel");
                });
                dialog.response.connect((response) => {
                    if (response == "delete") {
                        if (check_button.active) {
                            stream_interactor.get_module(MessageDeletion.IDENTITY).delete_globally(conversation, content_item);
                        } else {
                            stream_interactor.get_module(MessageDeletion.IDENTITY).delete_locally(conversation, content_item, conversation.account.bare_jid);
                        }
                    }
                });
                dialog.add_response("delete", "Delete for everyone");
                dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.add_response("cancel", "Cancel");
            } else {
                dialog.extra_child = new Label("This message <b>can't be deleted</b> for everyone. Would you like to remove it only for yourself?") { use_markup=true, wrap=true };
                dialog.add_response("delete", "Only delete for myself");
                dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.add_response("cancel", "Cancel");
                dialog.response.connect((response) => {
                    if (response == "delete") {
                        stream_interactor.get_module(MessageDeletion.IDENTITY).delete_locally(conversation, content_item, conversation.account.bare_jid);
                    }
                });
            }
            dialog.present(((Dino.Ui.Application)Dino.Application.get_default()).window);
        };
        return action;
    }
}