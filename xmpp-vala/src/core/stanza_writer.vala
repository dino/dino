namespace Xmpp.Core {
public class StanzaWriter {
    private OutputStream output;

    public StanzaWriter.for_stream(OutputStream output) {
        this.output = output;
    }

    public void write_node(StanzaNode node) throws XmlError {
        try {
            lock(output) {
                output.write_all(node.to_xml().data, null);
            }
        } catch (GLib.IOError e) {
            throw new XmlError.IO_ERROR(@"IOError in GLib: $(e.message)");
        }
    }

    public async void write(string s) throws XmlError {
        try {
            output.write_all(s.data, null);
        } catch (GLib.IOError e) {
            throw new XmlError.IO_ERROR(@"IOError in GLib: $(e.message)");
        }
    }
}
}
