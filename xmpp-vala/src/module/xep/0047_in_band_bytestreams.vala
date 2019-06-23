using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.InBandBytestreams {

private const string NS_URI = "http://jabber.org/protocol/ibb";
private const int SEQ_MODULUS = 65536;

public class Module : XmppStreamModule {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0047_in_band_bytestreams");

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
    }
    public override void detach(XmppStream stream) { }

    public void on_iq_set(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? data = iq.stanza.get_subnode("data", NS_URI);
        string? sid = data != null ? data.get_attribute("sid") : null;
        if (data == null || sid == null) {
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.bad_request("missing data node or sid")));
            return;
        }
        Connection? conn = stream.get_flag(Flag.IDENTITY).get_connection(sid);
        if (conn == null) {
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.item_not_found()));
            return;
        }

        int seq = data.get_attribute_int("seq");
        // TODO(hrxi): return an error on malformed base64 (need to do this
        // according to the xep)
        uint8[] content = Base64.decode(data.get_string_content());
        if (seq < 0 || seq != conn.remote_seq) {
            // TODO(hrxi): send an error and close the connection
            return;
        }
        conn.remote_seq = (conn.remote_seq + 1) % SEQ_MODULUS;

        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq));
        conn.on_data(stream, content);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class Connection {
    // TODO(hrxi): implement half-open states
    public enum State {
        UNCONNECTED,
        CONNECTING,
        CONNECTED,
        DISCONNECTING,
        DISCONNECTED,
        ERROR,
    }
    State state = UNCONNECTED;
    Jid receiver_full_jid;
    public string sid { get; private set; }
    int block_size;
    int local_seq = 0;
    int remote_ack = 0;
    internal int remote_seq = 0;

    public signal void on_error(XmppStream stream, string error);
    public signal void on_data(XmppStream stream, uint8[] data);
    public signal void on_ready(XmppStream stream);

    public Connection(Jid receiver_full_jid, string sid, int block_size) {
        this.receiver_full_jid = receiver_full_jid;
        this.sid = sid;
        this.block_size = block_size;
    }

    public void connect(XmppStream stream) {
        assert(state == UNCONNECTED);
        state = CONNECTING;

        StanzaNode open = new StanzaNode.build("open", NS_URI)
            .add_self_xmlns()
            .put_attribute("block-size", block_size.to_string())
            .put_attribute("sid", sid);

        Iq.Stanza iq = new Iq.Stanza.set(open) { to=receiver_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            assert(state == CONNECTING);
            if (!iq.is_error()) {
                state = CONNECTED;
                stream.get_flag(Flag.IDENTITY).add_connection(this);
                on_ready(stream);
            } else {
                set_error(stream, "connection failed");
            }
        });
    }

    void set_error(XmppStream stream, string error) {
        // TODO(hrxi): Send disconnect?
        state = ERROR;
        on_error(stream, error);
    }

    public void send(XmppStream stream, uint8[] bytes) {
        assert(state == CONNECTED);
        // TODO(hrxi): rate-limiting/merging?
        int seq = local_seq;
        local_seq = (local_seq + 1) % SEQ_MODULUS;
        StanzaNode data = new StanzaNode.build("data", NS_URI)
            .add_self_xmlns()
            .put_attribute("sid", sid)
            .put_attribute("seq", seq.to_string())
            .put_node(new StanzaNode.text(Base64.encode(bytes)));
        Iq.Stanza iq = new Iq.Stanza.set(data) { to=receiver_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            if (iq.is_error()) {
                set_error(stream, "sending failed");
                return;
            }
            if (remote_ack != seq) {
                set_error(stream, "out of order acks");
                return;
            }
            remote_ack = (remote_ack + 1) % SEQ_MODULUS;
            if (local_seq == remote_ack) {
                on_ready(stream);
            }
        });
    }

    public void close(XmppStream stream) {
        assert(state == CONNECTED);
        state = DISCONNECTING;
        // TODO(hrxi): should not do this, might still receive data
        stream.get_flag(Flag.IDENTITY).remove_connection(this);
        StanzaNode close = new StanzaNode.build("close", NS_URI)
            .add_self_xmlns()
            .put_attribute("sid", sid);
        Iq.Stanza iq = new Iq.Stanza.set(close) { to=receiver_full_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            assert(state == DISCONNECTING);
            if (iq.is_error()) {
                set_error(stream, "disconnecting failed");
                return;
            }
            state = DISCONNECTED;
        });
    }
}


public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "in_band_bytestreams");

    private HashMap<string, Connection> active = new HashMap<string, Connection>();

    public void add_connection(Connection conn) {
        active[conn.sid] = conn;
    }
    public Connection? get_connection(string sid) {
        return active.has_key(sid) ? active[sid] : null;
    }
    public void remove_connection(Connection conn) {
        active.unset(conn.sid);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
