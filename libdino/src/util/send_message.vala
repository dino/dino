using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

    public void send_message(Conversation conversation, string text, int reply_to_id, Message? correction_to, Gee.List<Xep.MessageMarkup.Span> markups) {
        StreamInteractor stream_interactor = Application.get_default().stream_interactor;

        Message out_message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(text, conversation);

        if (correction_to != null) {
            string correction_to_stanza_id = correction_to.edit_to ?? correction_to.stanza_id;
            out_message.edit_to = correction_to_stanza_id;
            stream_interactor.get_module(MessageCorrection.IDENTITY).set_correction(conversation, out_message, correction_to);
        }

        if (reply_to_id != 0) {
            ContentItem reply_to = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, reply_to_id);

            out_message.set_quoted_item(reply_to.id);

            // Store body with fallback
            string fallback = FallbackBody.get_quoted_fallback_body(reply_to);
            out_message.body = fallback + out_message.body;

            // Store fallback location
            var fallback_location = new Xep.FallbackIndication.FallbackLocation.partial_body(0, (int)fallback.char_count());
            var fallback_list = new ArrayList<Xep.FallbackIndication.Fallback>();
            fallback_list.add(new Xep.FallbackIndication.Fallback(Xep.Replies.NS_URI, new Xep.FallbackIndication.FallbackLocation[] { fallback_location }));
            out_message.set_fallbacks(fallback_list);

            // Adjust markups to new prefix
            foreach (var span in markups) {
                span.start_char += fallback.length;
                span.end_char += fallback.length;
            }
        }

        if (!markups.is_empty) {
            out_message.persist_markups(markups, out_message.id);
        }


        if (correction_to != null) {
            stream_interactor.get_module(MessageCorrection.IDENTITY).on_received_correction(conversation, out_message.id);
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(out_message, conversation);
            return;
        }

        stream_interactor.get_module(ContentItemStore.IDENTITY).insert_message(out_message, conversation);
        stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(out_message, conversation);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent(out_message, conversation);
    }
}