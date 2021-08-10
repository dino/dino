namespace Xmpp.Xep.Jingle {

    public abstract class ComponentConnection : Object {
        public uint8 component_id { get; set; default = 0; }
        public abstract async void terminate(bool we_terminated, string? reason_name = null, string? reason_text = null);
        public signal void connection_closed();
        public signal void connection_error(IOError e);
    }

    public abstract class DatagramConnection : ComponentConnection {
        public bool ready { get; set; default = false; }
        private string? terminate_reason_name = null;
        private string? terminate_reason_text = null;
        private bool terminated = false;

        public override async void terminate(bool we_terminated, string? reason_string = null, string? reason_text = null) {
            if (!terminated) {
                terminated = true;
                terminate_reason_name = reason_string;
                terminate_reason_text = reason_text;
                connection_closed();
            }
        }

        public signal void datagram_received(Bytes datagram);
        public abstract void send_datagram(Bytes datagram);
    }

    public class StreamingConnection : ComponentConnection {
        public Gee.Future<IOStream> stream { get { return promise.future; } }
        protected Gee.Promise<IOStream> promise = new Gee.Promise<IOStream>();
        private string? terminated = null;

        public async void set_stream(IOStream? stream) {
            if (stream == null) {
                promise.set_exception(new IOError.FAILED("Jingle connection failed"));
                return;
            }
            assert(!this.stream.ready);
            promise.set_value(stream);
            if (terminated != null) {
                yield stream.close_async();
            }
        }

        public void set_error(GLib.Error? e) {
            promise.set_exception(e);
        }

        public override async void terminate(bool we_terminated, string? reason_name = null, string? reason_text = null) {
            if (terminated == null) {
                terminated = (reason_name ?? "") + " - " + (reason_text ?? "") + @"we terminated? $we_terminated";
                if (stream.ready) {
                    yield stream.value.close_async();
                } else {
                    promise.set_exception(new IOError.FAILED("Jingle connection failed"));
                }
            }
        }
    }
}

