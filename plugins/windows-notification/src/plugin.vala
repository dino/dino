using Gee;
using Dino.Entities;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    private Dino.Application app;
    private ulong signal_handler = 0;

    [CCode (has_target = false)]
    private delegate void notification_callback(void* conv);

    [CCode (cname = "load_library", cheader_filename = "wintoast.h")]
    private static extern int load_library();

    [CCode (cname = "init_library", cheader_filename = "wintoast.h")]
    private static extern int init_library(notification_callback callback);

    [CCode (cname = "uninit_library", cheader_filename = "wintoast.h")]
    private static extern void uninit_library();

    [CCode (cname = "show_message", cheader_filename = "wintoast.h")]
    private static extern int show_message(char* sender, char* message, char* imagePath, char* protocolName, void *conv);

    private void onclick_callback() {
        // TODO:
        // This callback should:
        // * Open Dino
        // * Open Conversation from notification
        // * Go to line
        // The callback will probably need to receive at least one parameter more. Not difficult to do.
    }

    public void registered(Dino.Application app) {
        this.app = app;
        if (load_library() != 1 ||
            init_library(onclick_callback) != 1) {
            return;
        }

        signal_handler = app.stream_interactor.get_module(NotificationEvents.IDENTITY).notify_content_item.connect(on_notify);
    }

    public void shutdown() {
        if (signal_handler > 0) {
            app.stream_interactor.get_module(NotificationEvents.IDENTITY).notify_content_item.disconnect(on_notify);
        }
        uninit_library();
    }

    private void on_notify(ContentItem content_item, Conversation conversation) {
        string display_name = Dino.Ui.Util.get_conversation_display_name(app.stream_interactor, conversation);
        string text = "";
        switch (content_item.type_) {
            case MessageItem.TYPE:
                var message_item = (content_item as MessageItem);
                if (message_item != null) {
                    Message message = message_item.message;
                    if (message != null) {
                        text = message.body;
                    }
                }
                break;
            case FileItem.TYPE:
                FileItem file_item = content_item as FileItem;
                if (file_item != null) {
                    FileTransfer transfer = file_item.file_transfer;

                    bool file_is_image = transfer.mime_type != null && transfer.mime_type.has_prefix("image");
                    if (transfer.direction == Message.DIRECTION_SENT) {
                        text = file_is_image ? "Image sent" : "File sent";
                    } else {
                        text = file_is_image ? "Image received" : "File received";
                    }
                }
                break;
        }
        if (app.stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(conversation.counterpart, conversation.account)) {
            string muc_occupant = Dino.Ui.Util.get_participant_display_name(app.stream_interactor, conversation, content_item.jid);
            text = @"$muc_occupant: $text";
        }
        var avatar_manager = app.stream_interactor.get_module(AvatarManager.IDENTITY);
        var avatar = avatar_manager.get_avatar_filepath(conversation.account, conversation.counterpart);
        if (show_message(display_name, text, avatar, null, this) != 0) {
            stderr.printf("Error sending notification.");
        };
    }
}

}
