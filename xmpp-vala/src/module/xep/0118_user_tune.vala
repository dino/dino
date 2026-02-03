namespace Xmpp.Xep.UserTune {
    public const string NS_URI = "http://jabber.org/protocol/tune";

    public class Tune : Object {
        public string? artist { get; set; default = null; }
        public string? title { get; set; default = null; }
        public string? source { get; set; default = null; }  // album
        public int length { get; set; default = -1; }         // in seconds
        public string? track { get; set; default = null; }    // track number in cd
        public string? uri { get; set; default = null; }

        public Tune() {}

        public Tune.from_metadata(string? artist, string? title, string? source,
                                   int length, string? track, string? uri) {
            this.artist = artist;
            this.title = title;
            this.source = source;
            this.length = length;
            this.track = track;
            this.uri = uri;
        }

        public bool is_empty() {
            return artist == null && title == null && source == null &&
                   length < 0 && track == null && uri == null;
        }

        public bool equals(Tune? other) {
            if (other == null) return false;
            return artist == other.artist &&
                   title == other.title &&
                   source == other.source &&
                   length == other.length &&
                   track == other.track &&
                   uri == other.uri;
        }
    }

    public StanzaNode build_tune_node(Tune? tune) {
        StanzaNode tune_node = new StanzaNode.build("tune", NS_URI).add_self_xmlns();

        if (tune != null && !tune.is_empty()) {
            if (tune.artist != null && tune.artist.length > 0) {
                tune_node.put_node(new StanzaNode.build("artist", NS_URI).put_node(new StanzaNode.text(tune.artist)));
            }
            if (tune.title != null && tune.title.length > 0) {
                tune_node.put_node(new StanzaNode.build("title", NS_URI).put_node(new StanzaNode.text(tune.title)));
            }
            if (tune.source != null && tune.source.length > 0) {
                tune_node.put_node(new StanzaNode.build("source", NS_URI).put_node(new StanzaNode.text(tune.source)));
            }
            if (tune.length >= 0) {
                tune_node.put_node(new StanzaNode.build("length", NS_URI).put_node(new StanzaNode.text(tune.length.to_string())));
            }
            if (tune.track != null && tune.track.length > 0) {
                tune_node.put_node(new StanzaNode.build("track", NS_URI).put_node(new StanzaNode.text(tune.track)));
            }
            if (tune.uri != null && tune.uri.length > 0) {
                tune_node.put_node(new StanzaNode.build("uri", NS_URI).put_node(new StanzaNode.text(tune.uri)));
            }
        }

        return tune_node;
    }


    public Tune? parse_tune_node(StanzaNode? node) {
        if (node == null) return null;

        Tune tune = new Tune();

        StanzaNode? artist_node = node.get_subnode("artist", NS_URI);
        if (artist_node != null) tune.artist = artist_node.get_string_content();

        StanzaNode? title_node = node.get_subnode("title", NS_URI);
        if (title_node != null) tune.title = title_node.get_string_content();

        StanzaNode? source_node = node.get_subnode("source", NS_URI);
        if (source_node != null) tune.source = source_node.get_string_content();

        StanzaNode? length_node = node.get_subnode("length", NS_URI);
        if (length_node != null) {
            string? length_str = length_node.get_string_content();
            if (length_str != null) {
                try {
                    tune.length = int.parse(length_str);
                } catch (Error e) {
                    // Ignore invalid length values from peers, caused a crash in test
                }
            }
        }

        StanzaNode? track_node = node.get_subnode("track", NS_URI);
        if (track_node != null) tune.track = track_node.get_string_content();

        StanzaNode? uri_node = node.get_subnode("uri", NS_URI);
        if (uri_node != null) tune.uri = uri_node.get_string_content();

        return tune;
    }


    public async bool publish_tune(XmppStream stream, Tune? tune) {
        StanzaNode tune_node = build_tune_node(tune);

        Pubsub.PublishOptions options = new Pubsub.PublishOptions()
            .set_persist_items(true)
            .set_max_items("1")
            .set_send_last_published_item("on_sub_and_presence")
            .set_access_model(Pubsub.ACCESS_MODEL_PRESENCE);

        return yield stream.get_module(Pubsub.Module.IDENTITY).publish(
            stream, null, NS_URI, "current", tune_node, options
        );
    }

    // Clear tune by publishing empty tune 
    public async bool clear_tune(XmppStream stream) {
        return yield publish_tune(stream, null);
    }

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0118_user_tune");

        public signal void tune_received(XmppStream stream, Jid jid, Tune? tune);

        public override void attach(XmppStream stream) {
            stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(
                stream, NS_URI, on_pubsub_item, on_pubsub_retract, on_pubsub_delete
            );
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Pubsub.Module.IDENTITY).remove_filtered_notification(stream, NS_URI);
        }

        private void on_pubsub_item(XmppStream stream, Jid jid, string id, StanzaNode? node) {
            Tune? tune = parse_tune_node(node);
            tune_received(stream, jid, tune);
        }

        private void on_pubsub_retract(XmppStream stream, Jid jid, string id) {
            tune_received(stream, jid, null);
        }

        private void on_pubsub_delete(XmppStream stream, Jid jid) {
            tune_received(stream, jid, null);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}

