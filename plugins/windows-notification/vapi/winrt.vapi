[CCode (cheader_filename = "gobject/winrt-glib.h")]
namespace winrt {
    public bool InitApartment();

    [CCode (type_id = "winrt_event_token_get_type ()")]
	public class EventToken : GLib.Object {
        [CCode (has_construct_function = false)]
		public EventToken();
        public int64 value { get; }
        [CCode(cname = "winrt_event_token_operator_bool")]
        public bool IsValid();
    }
}