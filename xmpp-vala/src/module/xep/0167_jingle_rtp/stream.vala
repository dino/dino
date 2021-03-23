public abstract class Xmpp.Xep.JingleRtp.Stream : Object {
    public Jingle.Content content { get; protected set; }
    public string name { get {
        return content.content_name;
    }}
    public string? media { get {
        var content_params = content.content_params;
        if (content_params is Parameters) {
            return ((Parameters)content_params).media;
        }
        return null;
    }}
    public JingleRtp.PayloadType? payload_type { get {
        var content_params = content.content_params;
        if (content_params is Parameters) {
            return ((Parameters)content_params).agreed_payload_type;
        }
        return null;
    }}
    public JingleRtp.Crypto? local_crypto { get {
        var content_params = content.content_params;
        if (content_params is Parameters) {
            return ((Parameters)content_params).local_crypto;
        }
        return null;
    }}
    public JingleRtp.Crypto? remote_crypto { get {
        var content_params = content.content_params;
        if (content_params is Parameters) {
            return ((Parameters)content_params).remote_crypto;
        }
        return null;
    }}
    public bool sending { get {
        return content.session.senders_include_us(content.senders);
    }}
    public bool receiving { get {
        return content.session.senders_include_counterpart(content.senders);
    }}

    protected Stream(Jingle.Content content) {
        this.content = content;
    }

    public signal void on_send_rtp_data(Bytes bytes);
    public signal void on_send_rtcp_data(Bytes bytes);

    public abstract void on_recv_rtp_data(Bytes bytes);
    public abstract void on_recv_rtcp_data(Bytes bytes);

    public abstract void on_rtp_ready();
    public abstract void on_rtcp_ready();

    public abstract void create();
    public abstract void destroy();

    public string to_string() {
        return @"$name/$media stream in $(content.session.sid)";
    }
}