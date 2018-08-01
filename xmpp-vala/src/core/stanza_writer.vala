namespace Xmpp {

public class StanzaWriter {
    private OutputStream output;

    private Queue<SourceFuncWrapper> queue = new Queue<SourceFuncWrapper>();
    private bool running = false;

    public StanzaWriter.for_stream(OutputStream output) {
        this.output = output;
    }

    public async void write_node(StanzaNode node) throws XmlError {
        yield write_data(node.to_xml().data);
    }

    public async void write(string s) throws XmlError {
        yield write_data(s.data);
    }

    private async void write_data(uint8[] data) throws XmlError {
        if (running) {
            queue.push_tail(new SourceFuncWrapper(write_data.callback));
            yield;
        }
        running = true;
        try {
            yield output.write_all_async(data, 0, null, null);
            SourceFuncWrapper? sfw = queue.pop_head();
            if (sfw != null) {
                sfw.sfun();
            }
        } catch (GLib.Error e) {
            throw new XmlError.IO(@"IOError in GLib: $(e.message)");
        } finally {
            running = false;
        }
    }
}

public class SourceFuncWrapper : Object {

    public SourceFunc sfun;

    public SourceFuncWrapper(owned SourceFunc sfun) {
        this.sfun = (owned)sfun;
    }
}

}
