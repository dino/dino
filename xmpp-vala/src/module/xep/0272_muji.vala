using Gee;
namespace Xmpp.Xep.Muji {

    public const string NS_URI = "urn:xmpp:jingle:muji:0";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0272_muji");

        public async GroupCall? join_call(XmppStream stream, Jid muc_jid, bool video) {
            StanzaNode initial_muji_node = new StanzaNode.build("muji", NS_URI).add_self_xmlns()
                    .put_node(new StanzaNode.build("preparing", NS_URI));

            var group_call = new GroupCall(muc_jid);
            stream.get_flag(Flag.IDENTITY).calls[muc_jid] = group_call;

            group_call.our_nick = "%08x".printf(Random.next_int());
            debug(@"[%s] MUJI joining as %s", stream.get_flag(Bind.Flag.IDENTITY).my_jid.to_string(), group_call.our_nick);
            Xep.Muc.JoinResult? result = yield stream.get_module(Muc.Module.IDENTITY).enter(stream, muc_jid, group_call.our_nick, null, null, false, initial_muji_node);
            if (result == null || result.nick == null) return null;
            debug(@"[%s] MUJI joining as %s done", stream.get_flag(Bind.Flag.IDENTITY).my_jid.to_string(), group_call.our_nick);

            // Determine all participants that have finished preparation. Those are the ones we have to initiate the call with.
            Gee.List<Presence.Stanza> other_presences = yield wait_for_preparing_peers(stream, muc_jid);
            var finished_real_jids = new ArrayList<Jid>(Jid.equals_func);
            foreach (Presence.Stanza presence in other_presences) {
                if (presence.stanza.get_deep_subnode(NS_URI + ":muji", NS_URI + ":preparing") != null) continue;
                Jid? real_jid = stream.get_flag(Muc.Flag.IDENTITY).get_real_jid(presence.from);
                if (real_jid == null) {
                    warning("Don't know the real jid for %s", presence.from.to_string());
                    continue;
                }
                finished_real_jids.add(real_jid);
            }
            group_call.peers_to_connect_to.add_all(finished_real_jids);

            // Build+send our own MUJI presence
            StanzaNode muji_node = new StanzaNode.build("muji", NS_URI).add_self_xmlns();

            foreach (string media in video ? new string[] { "audio", "video" } : new string[] { "audio" }) {
                StanzaNode content_node = new StanzaNode.build("content", Xep.Jingle.NS_URI).add_self_xmlns()
                        .put_attribute("name", media);
                StanzaNode description_node = new StanzaNode.build("description", Xep.JingleRtp.NS_URI).add_self_xmlns()
                        .put_attribute("media", media);
                content_node.put_node(description_node);

                Gee.List<Xep.JingleRtp.PayloadType> payload_types = null;
                if (other_presences.is_empty) {
                    payload_types = yield stream.get_module(Xep.JingleRtp.Module.IDENTITY).get_supported_payloads(media);
                } else {
                    yield compute_payload_intersection(stream, group_call, media);
                    payload_types = group_call.current_payload_intersection[media];
                }
                foreach (Xep.JingleRtp.PayloadType payload_type in payload_types) {
                    description_node.put_node(payload_type.to_xml().add_self_xmlns());
                }
                muji_node.put_node(content_node);
            }

            Presence.Stanza presence_stanza = new Presence.Stanza() { to=muc_jid.with_resource(group_call.our_nick) };
            presence_stanza.stanza.put_node(muji_node);
            stream.get_module(Presence.Module.IDENTITY).send_presence(stream, presence_stanza);

            return group_call;
        }

        private async Gee.List<Presence.Stanza> wait_for_preparing_peers(XmppStream stream, Jid muc_jid) {
            var promise = new Promise<Gee.List<Presence.Stanza>>();

            ArrayList<Jid> preparing_peers = new ArrayList<Jid>(Jid.equals_func);

            Gee.List<Presence.Stanza> presences = get_other_presences(stream, muc_jid);

            foreach (Presence.Stanza presence in presences) {
                StanzaNode? preparing_node = presence.stanza.get_deep_subnode(NS_URI + ":muji", NS_URI + ":preparing");
                if (preparing_node != null) {
                    preparing_peers.add(presence.from);
                }
            }

            debug("[%s] MUJI waiting for %i/%i peers", stream.get_flag(Bind.Flag.IDENTITY).my_jid.to_string(), preparing_peers.size, presences.size);

            if (preparing_peers.is_empty) {
                return presences;
            }

            GroupCall group_call = stream.get_flag(Flag.IDENTITY).calls[muc_jid];
            group_call.waiting_for_finish_prepares[promise] = preparing_peers;

            return yield promise.future.wait_async();
        }

        private async void compute_payload_intersection(XmppStream stream, GroupCall group_call, string media) {
            Gee.List<Presence.Stanza> presences = get_other_presences(stream, group_call.muc_jid);
            if (presences.is_empty) return;

            Gee.List<Xep.JingleRtp.PayloadType> intersection = parse_payload_types(stream, media, presences[0]);
            var remove_payloads = new ArrayList<Xep.JingleRtp.PayloadType>();

            // Check if all peers support the payloads
            foreach (Presence.Stanza presence in presences) {
                Gee.List<Xep.JingleRtp.PayloadType> peer_payload_types = parse_payload_types(stream, media, presence);

                foreach (Xep.JingleRtp.PayloadType payload_type in intersection) {
                    if (!peer_payload_types.contains(payload_type)) {
                        remove_payloads.add(payload_type);
                    }
                }
            }
            // Check if we support the payloads
            foreach (Xep.JingleRtp.PayloadType payload_type in intersection) {
                if (!yield stream.get_module(Xep.JingleRtp.Module.IDENTITY).is_payload_supported(media, payload_type)) {
                    remove_payloads.add(payload_type);
                }
            }
            // Remove payloads not supported by everyone
            foreach (Xep.JingleRtp.PayloadType payload_type in remove_payloads) {
                intersection.remove(payload_type);
            }

            // Check if the payload intersection changed (if so: notify)
            bool changed = !group_call.current_payload_intersection.has_key(media) ||
                    !group_call.current_payload_intersection[media].contains_all(intersection) ||
                    !intersection.contains_all(group_call.current_payload_intersection[media]);

            if (changed) {
                group_call.current_payload_intersection[media] = intersection;
                group_call.codecs_changed(intersection);
            }
        }

        private Gee.List<Xep.JingleRtp.PayloadType> parse_payload_types(XmppStream stream, string media, Presence.Stanza presence) {
            Gee.List<Xep.JingleRtp.PayloadType> ret = new ArrayList<Xep.JingleRtp.PayloadType>(Xep.JingleRtp.PayloadType.equals_func);

            foreach (StanzaNode content_node in presence.stanza.get_deep_subnodes(NS_URI + ":muji", Xep.Jingle.NS_URI + ":content")) {
                StanzaNode? description_node = content_node.get_subnode("description", Xep.JingleRtp.NS_URI);
                if (description_node == null) continue;

                if (description_node.get_attribute("media") == media) {
                    Gee.List<StanzaNode> payload_nodes = description_node.get_subnodes("payload-type", Xep.JingleRtp.NS_URI);
                    foreach (StanzaNode payload_node in payload_nodes) {
                        Xep.JingleRtp.PayloadType payload_type = Xep.JingleRtp.PayloadType.parse(payload_node);
                        ret.add(payload_type);
                    }
                }
            }
            return ret;
        }

        private void on_received_available(XmppStream stream, Presence.Stanza presence) {
            StanzaNode? muji_node = presence.stanza.get_subnode("muji", NS_URI);
            if (muji_node == null) return;

            var flag = stream.get_flag(Flag.IDENTITY);
            GroupCall? group_call = flag.calls.get(presence.from.bare_jid);
            if (group_call == null) return;

            if (presence.from.resourcepart == group_call.our_nick) return;

            foreach (StanzaNode content_node in muji_node.get_subnodes("content", Xep.Jingle.NS_URI)) {
                StanzaNode? description_node = content_node.get_subnode("description", Xep.JingleRtp.NS_URI);
                if (description_node == null) continue;

                string? media = description_node.get_attribute("media");
                if (media == null) continue;

                compute_payload_intersection.begin(stream, group_call, media);
            }

            StanzaNode? prepare_node = muji_node.get_subnode("preparing", NS_URI);
            if (prepare_node == null) {
                on_jid_finished_preparing(stream, presence.from, group_call);

                if (!group_call.peers.contains(presence.from)) {
                    // A new peer finished preparing
                    Jid? real_jid = stream.get_flag(Muc.Flag.IDENTITY).get_real_jid(presence.from);
                    if (real_jid == null) {
                        warning("Don't know the real jid for %s", presence.from.to_string());
                        return;
                    }
                    debug("Muji peer joined %s / %s\n", real_jid.to_string(), presence.from.to_string());
                    group_call.peers.add(presence.from);
                    group_call.real_jids[presence.from] = real_jid;
                    group_call.peer_joined(real_jid);
                }
            }
        }

        private void on_received_unavailable(XmppStream stream, Presence.Stanza presence) {
            Flag flag = stream.get_flag(Flag.IDENTITY);
            GroupCall? group_call = flag.calls[presence.from.bare_jid];
            if (group_call == null) return;

            debug("Muji peer left %s / %s", group_call.real_jids.has_key(presence.from) ? group_call.real_jids[presence.from].to_string() : "Unknown real JID", presence.from.to_string());
            on_jid_finished_preparing(stream, presence.from, group_call);
            group_call.peers.remove(presence.from);
            group_call.peers_to_connect_to.remove(presence.from);
            if (group_call.real_jids.has_key(presence.from)) {
                group_call.peer_left(group_call.real_jids[presence.from]);
            }
            group_call.real_jids.unset(presence.from);
        }

        private void on_jid_finished_preparing(XmppStream stream, Jid jid, GroupCall group_call) {
            debug("Muji peer finished preparing %s", jid.to_string());
            foreach (Promise<Gee.List<Presence.Stanza>> promise in group_call.waiting_for_finish_prepares.keys) {
                debug("Waiting for finish prepares %i", group_call.waiting_for_finish_prepares[promise].size);
                Gee.List<Jid> outstanding_prepares = group_call.waiting_for_finish_prepares[promise];
                if (outstanding_prepares.contains(jid)) {
                    outstanding_prepares.remove(jid);
                    debug("Waiting for finish prepares %i", group_call.waiting_for_finish_prepares[promise].size);

                    if (outstanding_prepares.is_empty) {
                        Gee.List<Presence.Stanza> presences = get_other_presences(stream, jid.bare_jid);
                        promise.set_value(presences);
                    }
                }
            }
        }

        private Gee.List<Presence.Stanza> get_other_presences(XmppStream stream, Jid muc_jid) {
            Gee.List<Presence.Stanza> presences = stream.get_flag(Presence.Flag.IDENTITY).get_presences(muc_jid);
            string? own_nick = stream.get_flag(Flag.IDENTITY).calls[muc_jid].our_nick;

            var remove_presences = new ArrayList<Presence.Stanza>();
            foreach (Presence.Stanza presence in presences) {
                if (presence.from.resourcepart == own_nick) {
                    remove_presences.add(presence);
                }
                StanzaNode? muji_node = presence.stanza.get_subnode("muji", NS_URI);
                if (muji_node == null) {
                    remove_presences.add(presence);
                }
            }
            presences.remove_all(remove_presences);
            return presences;
        }

        public override void attach(XmppStream stream) {
            stream.add_flag(new Flag());
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
            stream.get_module(Presence.Module.IDENTITY).received_available.connect(on_received_available);
            stream.get_module(Presence.Module.IDENTITY).received_unavailable.connect(on_received_unavailable);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        }

        public override string get_ns() {
            return NS_URI;
        }

        public override string get_id() {
            return IDENTITY.id;
        }
    }

    public class GroupCall {
        public string our_nick;
        public Jid muc_jid;
        public ArrayList<Jid> peers_to_connect_to = new ArrayList<Jid>(Jid.equals_func);
        public ArrayList<Jid> peers = new ArrayList<Jid>(Jid.equals_func);
        public HashMap<Jid, Jid> real_jids = new HashMap<Jid, Jid>(Jid.hash_func, Jid.equals_func);
        public HashMap<Promise, Gee.List<Jid>> waiting_for_finish_prepares = new HashMap<Promise, Gee.List<Jid>>();
        public HashMap<string, Gee.List<Xep.JingleRtp.PayloadType>> current_payload_intersection = new HashMap<string, Gee.List<Xep.JingleRtp.PayloadType>>();

        public signal void peer_joined(Jid real_jid);
        public signal void peer_left(Jid real_jid);
        public signal void codecs_changed(Gee.List<Xep.JingleRtp.PayloadType> payload_types);

        public GroupCall(Jid muc_jid) {
            this.muc_jid = muc_jid;
        }

        public void leave(XmppStream stream) {
            stream.get_module(Xep.Muc.Module.IDENTITY).exit(stream, muc_jid);
            stream.get_flag(Flag.IDENTITY).calls.unset(muc_jid);
        }
    }

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "muji");

        public HashMap<Jid, GroupCall> calls = new HashMap<Jid, GroupCall>(Jid.hash_bare_func, Jid.equals_bare_func);

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}