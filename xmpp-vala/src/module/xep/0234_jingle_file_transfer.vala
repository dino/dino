using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.JingleFileTransfer {

private const string NS_URI = "urn:xmpp:jingle:apps:file-transfer:5";

public errordomain Error {
    FILE_INACCESSIBLE,
}

public class Module : XmppStreamModule {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0234_jingle_file_transfer");

    public override void attach(XmppStream stream) {
        stream.add_flag(new Flag());
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
    }
    public override void detach(XmppStream stream) { }

    public bool is_available(XmppStream stream, Jid full_jid) {
        bool? has_feature = stream.get_flag(ServiceDiscovery.Flag.IDENTITY).has_entity_feature(full_jid, NS_URI);
        if (has_feature == null || !(!)has_feature) {
            return false;
        }
        return stream.get_module(Jingle.Module.IDENTITY).is_available(stream, Jingle.TransportType.STREAMING, full_jid);
    }

    public void offer_file(XmppStream stream, Jid receiver_full_jid, string path) throws Error {
        File file = File.new_for_path(path);
        FileInputStream input_stream;
        int64 size;
        try {
            input_stream = file.read();
        } catch (GLib.Error e) {
            throw new Error.FILE_INACCESSIBLE(@"could not open the file \"$path\" for reading: $(e.message)");
        }
        try {
            size = input_stream.query_info(FileAttribute.STANDARD_SIZE).get_size();
        } catch (GLib.Error e) {
            throw new Error.FILE_INACCESSIBLE(@"could not read the size: $(e.message)");
        }

        offer_file_stream(stream, receiver_full_jid, input_stream, file.get_basename(), size);
    }

    public void offer_file_stream(XmppStream stream, Jid receiver_full_jid, InputStream input_stream, string basename, int64 size) {
        StanzaNode description = new StanzaNode.build("description", NS_URI)
            .add_self_xmlns()
            .put_node(new StanzaNode.build("file", NS_URI)
                .put_node(new StanzaNode.build("name", NS_URI).put_node(new StanzaNode.text(basename)))
                .put_node(new StanzaNode.build("size", NS_URI).put_node(new StanzaNode.text(size.to_string()))));
                // TODO(hrxi): Add the mandatory hash field

        Jingle.Session? session = stream.get_module(Jingle.Module.IDENTITY)
            .create_session(stream, Jingle.TransportType.STREAMING, receiver_full_jid, Jingle.Senders.INITIATOR, "a-file-offer", description); // TODO(hrxi): Why "a-file-offer"?

        FileTransfer transfer = new FileTransfer(input_stream);
        session.on_ready.connect(transfer.send_data);
        stream.get_flag(Flag.IDENTITY).add_file_transfer(transfer);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class FileTransfer : Object {
    InputStream input_stream;
    public FileTransfer(InputStream input_stream) {
        this.input_stream = input_stream;
    }
    public void send_data(Jingle.Session session, XmppStream stream) {
        uint8 buffer[4096];
        ssize_t read;
        try {
            if((read = input_stream.read(buffer)) != 0) {
                session.send(stream, buffer[0:read]);
            } else {
                session.close_connection(stream);
            }
        } catch (GLib.IOError e) {
            session.set_application_error(stream);
        }
        // TODO(hrxi): remove file transfer
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "jingle_file_transfer");

    private Gee.List<FileTransfer> transfers = new ArrayList<FileTransfer>();

    public void add_file_transfer(FileTransfer transfer) { transfers.add(transfer); }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
