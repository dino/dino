using Gee;
using Dino.Entities;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    public Dino.Application app;

    //  private class ConvData {
    //      public int ReadUpToId;
    //      public int Timestamp;
    //  }
    //  private int interval = 0;
    //  private HashMap<int, ConvData> conv_data = new HashMap<int, ConvData>();

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

        app.stream_interactor.get_module(NotificationEvents.IDENTITY).notify_content_item.connect((item, conversation) => {
            if (item.type_ == "message") {
                // key: conversation.id value: { conversation.read_up_to.id, last-time-notification-send }
                //  var conv = conv_data.get(conversation.id);
                //  if (conv.ReadUpToId == conversation.read_up_to.id) {
                //    if (now < conv.Timestamp + interval) {
                //        return;
                //    }
                //  }
                var message_item = (MessageItem)item;
                //var message = item.encryption == Encryption.NONE ? message_item.message.body : "*encrypted*";
                var message = message_item.message.body;
                var sender = conversation.nickname != null ? conversation.nickname : conversation.counterpart.to_string();
                if (show_message(sender, message, "", "", this) != 0) {
                    stderr.printf("Error sending notification.");
                };
            }
        });
    }

    public void shutdown() {
        uninit_library();
    }
}

}
