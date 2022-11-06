using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.PhoneRinger {

public class Plugin : RootInterface, NotificationProvider, Object {

    private Canberra.Context sound_context;
    private const int ringer_id = 0;
    private const int dialer_id = 1;
    private Canberra.Proplist ringer_props;
    private Canberra.Proplist dialer_props;

    private void loop_ringer() {
        sound_context.play_full(ringer_id, ringer_props, (c, id, code) => {
            if (code != Canberra.Error.CANCELED) {
                Idle.add(() => {
                    loop_ringer();
                    return Source.REMOVE;
                });
            }
        });
    }

    private void loop_dialer() {
        sound_context.play_full(dialer_id, dialer_props, (c, id, code) => {
            if (code != Canberra.Error.CANCELED) {
                Idle.add(() => {
                    loop_dialer();
                    return Source.REMOVE;
                });
            }
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
        loop_ringer();
    }

    public async void retract_call_notification(Call call, Conversation conversation){
        sound_context.cancel(ringer_id);
    }

    public async void notify_dialing(){
        loop_dialer();
    }

    public async void retract_dialing(){
        sound_context.cancel(dialer_id);
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
