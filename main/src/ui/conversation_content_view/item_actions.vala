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

    public Plugins.MessageAction get_file_link_action(ContentItem content_item, Conversation conversation, StreamInteractor stream_interactor) {
        Plugins.MessageAction action = new Plugins.MessageAction();
        action.name = "copy-file-link";
        action.icon_name = "dino-chain-link-symbolic";
        action.tooltip = _("Copy file link");
        action.callback = () => {
            GLib.Application.get_default().activate_action("copy-file-link", new GLib.Variant.tuple(new GLib.Variant[] { new GLib.Variant.int32(conversation.id), new GLib.Variant.int32(content_item.id) }));
        };
	return action;
    }
}
