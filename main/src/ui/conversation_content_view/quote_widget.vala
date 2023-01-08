using Dino.Ui.ConversationSummary;
using Gee;
using Gtk;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui.Quote {

    public class Model : Object {
        public signal void aborted();
        public signal void jump_to();

        public string display_name { get; set; }
        public string message { get; set; }
        public DateTime message_time { get; set; }

        public StreamInteractor stream_interactor { get; set; }
        public Conversation conversation { get; set; }
        public Jid author_jid { get; set; }

        public bool can_abort { get; set; default=false; }

        public Model.from_content_item(ContentItem content_item, Conversation conversation, StreamInteractor stream_interactor) {
            this.display_name = Util.get_participant_display_name(stream_interactor, conversation, content_item.jid, true);
            if (content_item.type_ == MessageItem.TYPE) {
                var message = ((MessageItem) content_item).message;
                this.message = Dino.message_body_without_reply_fallback(message);
            } else if (content_item.type_ == FileItem.TYPE) {
                this.message = "[File]";
            }
            this.message_time = content_item.time;

            this.stream_interactor = stream_interactor;
            this.conversation = conversation;
            this.author_jid = content_item.jid;
        }
    }

    public Widget get_widget(Model model) {
        Builder builder = new Builder.from_resource("/im/dino/Dino/quote.ui");
        AvatarImage avatar = (AvatarImage) builder.get_object("avatar");
        Label author = (Label) builder.get_object("author");
        Label time = (Label) builder.get_object("time");
        Label message = (Label) builder.get_object("message");
        Button abort_button = (Button) builder.get_object("abort-button");

        avatar.set_conversation_participant(model.stream_interactor, model.conversation, model.author_jid);
        model.bind_property("display-name", author, "label", BindingFlags.SYNC_CREATE);
        model.bind_property("message-time", time, "label", BindingFlags.SYNC_CREATE, (_, from_value, ref to_value) => {
            DateTime message_time = (DateTime) from_value;
            to_value = ConversationItemSkeleton.get_relative_time(message_time);
            return true;
        });
        model.bind_property("message", message, "label", BindingFlags.SYNC_CREATE);
        model.bind_property("can-abort", abort_button, "visible", BindingFlags.SYNC_CREATE);

        abort_button.clicked.connect(() => {
            model.aborted();
        });

        Widget outer = builder.get_object("outer") as Widget;

        GestureClick gesture_click_controller = new GestureClick();
        outer.add_controller(gesture_click_controller);
        gesture_click_controller.pressed.connect(() => {
            model.jump_to();
        });

        return outer;
    }
}

