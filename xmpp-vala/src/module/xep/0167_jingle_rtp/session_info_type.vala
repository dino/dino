using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.JingleRtp {

    public enum CallSessionInfo {
        ACTIVE,
        HOLD,
        UNHOLD,
        MUTE,
        UNMUTE,
        RINGING
    }

    public class SessionInfoType : Jingle.SessionInfoNs, Object {
        public const string NS_URI = "urn:xmpp:jingle:apps:rtp:info:1";
        public string ns_uri { get { return NS_URI; } }

        public signal void info_received(Jingle.Session session, CallSessionInfo info);
        public signal void mute_update_received(Jingle.Session session, bool mute, string name);

        public void handle_content_session_info(XmppStream stream, Jingle.Session session, StanzaNode info, Iq.Stanza iq) throws Jingle.IqError {
            switch (info.name) {
                case "active":
                    info_received(session, CallSessionInfo.ACTIVE);
                    break;
                case "hold":
                    info_received(session, CallSessionInfo.HOLD);
                    break;
                case "unhold":
                    info_received(session, CallSessionInfo.UNHOLD);
                    break;
                case "mute":
                    string? name = info.get_attribute("name");
                    mute_update_received(session, true, name);
                    info_received(session, CallSessionInfo.MUTE);
                    break;
                case "unmute":
                    string? name = info.get_attribute("name");
                    mute_update_received(session, false, name);
                    info_received(session, CallSessionInfo.UNMUTE);
                    break;
                case "ringing":
                    info_received(session, CallSessionInfo.RINGING);
                    break;
            }
        }

        public void send_mute(Jingle.Session session, bool mute, string media) {
            string node_name = mute ? "mute" : "unmute";

            foreach (Jingle.Content content in session.contents) {
                Parameters? parameters = content.content_params as Parameters;
                if (parameters != null && parameters.media == media) {
                    StanzaNode session_info_content = new StanzaNode.build(node_name, NS_URI)
                            .add_self_xmlns()
                            .put_attribute("name", content.content_name)
                            .put_attribute("creator", content.content_creator.to_string());
                    session.send_session_info(session_info_content);
                }
            }
        }

        public void send_ringing(Jingle.Session session) {
            StanzaNode session_info_content = new StanzaNode.build("ringing", NS_URI).add_self_xmlns();
            session.send_session_info(session_info_content);
        }
    }
}
