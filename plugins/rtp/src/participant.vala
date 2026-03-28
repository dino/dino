using Gee;
using Xmpp;

public class Dino.Plugins.Rtp.Participant {
    public Jid full_jid { get; private set; }

    protected Gst.Pipeline pipe;
    private Map<Stream, uint32> ssrcs = new HashMap<Stream, uint32>();

    public Participant(Gst.Pipeline pipe, Jid full_jid) {
        this.pipe = pipe;
        this.full_jid = full_jid;
    }

    public uint32 get_ssrc(Stream stream) {
        if (ssrcs.has_key(stream)) {
            return ssrcs[stream];
        }
        return 0;
    }

    public void set_ssrc(Stream stream, uint32 ssrc) {
        if (ssrcs.has_key(stream)) {
            warning("Learning ssrc %ul for %s in %s when it is already known as %ul", ssrc, full_jid.to_string(), stream.to_string(), ssrcs[stream]);
        } else {
            stream.on_destroy.connect(unset_ssrc);
        }
        ssrcs[stream] = ssrc;
    }

    public void unset_ssrc(Stream stream) {
        ssrcs.unset(stream);
        stream.on_destroy.disconnect(unset_ssrc);
    }

    public string to_string() {
        return @"participant $full_jid";
    }
}