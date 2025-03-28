using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.PhoneRinger {

public class Plugin : RootInterface, NotificationProvider, Object {

    private const int GAP = 1;
    private const int RINGER_ID = 0;
    private const int DIALER_ID = 1;
    private Canberra.Context sound_context;
    private Canberra.Proplist ringer_props;
    private Canberra.Proplist dialer_props;
    private bool ringing = false;
    private bool dialing = false;

    private void loop_ringer() {
        sound_context.play_full(RINGER_ID, ringer_props, (c, id, code) => {
            if (code == Canberra.Error.CANCELED) return;
            Timeout.add_seconds(GAP, () => {
                if (!ringing) return Source.REMOVE;
                loop_ringer();
                return Source.REMOVE;
            });
        });
    }

    private void loop_dialer() {
        sound_context.play_full(DIALER_ID, dialer_props, (c, id, code) => {
            if (code == Canberra.Error.CANCELED) return;
            Timeout.add_seconds(GAP, () => {
                if (!dialing) return Source.REMOVE;
                loop_dialer();
                return Source.REMOVE;
            });
        });
    }

    public void registered(Dino.Application app) {

        Canberra.Context.create(out sound_context);
        Canberra.Proplist.create(out ringer_props);
        Canberra.Proplist.create(out dialer_props);
        ringer_props.sets(Canberra.PROP_EVENT_ID, "phone-incoming-call");
        ringer_props.sets(Canberra.PROP_EVENT_DESCRIPTION, "Incoming call");
        dialer_props.sets(Canberra.PROP_EVENT_ID, "phone-outgoing-calling");
        dialer_props.sets(Canberra.PROP_EVENT_DESCRIPTION, "Outgoing call");

        NotificationEvents notification_events = app.stream_interactor.get_module(NotificationEvents.IDENTITY);
        notification_events.register_notification_provider.begin(this);
    }

    public void shutdown() { }

    public async void notify_call(Call call, Conversation conversation, bool video, bool multiparty, string conversation_display_name){
        ringing = true;
        loop_ringer();
    }

    public async void retract_call_notification(Call call, Conversation conversation){
        ringing = false;
        sound_context.cancel(RINGER_ID);
    }

    public async void notify_dialing(){
        dialing = true;
        loop_dialer();
    }

    public async void retract_dialing(){
        dialing = false;
        sound_context.cancel(DIALER_ID);
    }

    public double get_priority(){
        return 0;
    }

    public async void notify_message(Message message, Conversation conversation, string conversation_display_name, string? participant_display_name){}
    public async void notify_file(FileTransfer file_transfer, Conversation conversation, bool is_image, string conversation_display_name, string? participant_display_name){}
    public async void notify_subscription_request(Conversation conversation){}
    public async void notify_connection_error(Account account, ConnectionManager.ConnectionError error){}
    public async void notify_muc_invite(Account account, Jid room_jid, Jid from_jid, string inviter_display_name){}
    public async void notify_voice_request(Conversation conversation, Jid from_jid){}
    public async void retract_content_item_notifications(){}
    public async void retract_conversation_notifications(Conversation conversation){}

}

}
