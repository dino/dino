using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.HttpFiles {

public class FileProvider : Dino.FileProvider, Object {
    public string id { get { return "http"; } }

    private StreamInteractor stream_interactor;
    private Regex url_regex;

    private Gee.List<string> ignore_once = new ArrayList<string>();

    public FileProvider(StreamInteractor stream_interactor, Dino.Database dino_db) {
        this.stream_interactor = stream_interactor;
        this.url_regex = new Regex("""^(?i)\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))$""");

        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new ReceivedMessageListener(this));
        stream_interactor.get_module(Manager.IDENTITY).uploaded.connect((file_transfer, url) => {
            ignore_once.add(url);
        });
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "DECRYPT"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private FileProvider outer;
        private StreamInteractor stream_interactor;

        public ReceivedMessageListener(FileProvider outer) {
            this.outer = outer;
            this.stream_interactor = outer.stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (!outer.url_regex.match(message.body)) return false;
            Jid relevant_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(message.from, conversation.account) ?? conversation.counterpart;
            bool in_roster = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(conversation.account, relevant_jid) != null;
            if (message.direction == Message.DIRECTION_RECEIVED && !in_roster) return false;

            string? oob_url = Xmpp.Xep.OutOfBandData.get_url_from_message(message.stanza);
            if (oob_url != null && oob_url == message.body) {
                yield outer.download_url(message, conversation);
            }
            return false;
        }
    }

    private async bool download_url(Message message, Conversation conversation) {
        bool success = false;
        string original_url = message.body.strip();
        string url = this.stream_interactor.get_module(FileManager.IDENTITY).rewrite_incoming_url(message.body.strip());
        var session = new Soup.Session();
        var head_message = new Soup.Message("HEAD", url);
        if (head_message != null) {
            SourceFunc callback = download_url.callback;
            session.send_async.begin(head_message, null, (obj, res) => {
                string? content_type = null, content_length = null;
                head_message.response_headers.foreach((name, val) => {
                    if (name == "Content-Type") content_type = val;
                    if (name == "Content-Length") content_length = val;
                });
                if (content_length != null && int.parse(content_length) < 5000000) {
                    FileTransfer file_transfer = new FileTransfer();
                    try {
                        Soup.Request request = session.request(url);
                        request.send_async.begin(null, (obj, res) => {
                            try {
                                file_transfer.input_stream = request.send_async.end(res);
                            } catch (Error e) {
                                Idle.add((owned)callback);
                                return;
                            }
                            file_transfer.account = conversation.account;
                            file_transfer.counterpart = message.counterpart;
                            file_transfer.ourpart = message.ourpart;
                            file_transfer.encryption = Encryption.NONE;
                            file_transfer.time = message.time;
                            file_transfer.local_time = message.local_time;
                            file_transfer.direction = message.direction;
                            file_transfer.file_name = url.substring(url.last_index_of("/") + 1);
                            file_transfer.mime_type = content_type;
                            file_transfer.size = int.parse(content_length);
                            file_transfer.state = FileTransfer.State.NOT_STARTED;
                            file_transfer.provider = 0;
                            file_transfer.info = message.id.to_string() + ":" + original_url;
                            file_incoming(file_transfer);
                            success = true;
                            Idle.add((owned)callback);
                        });
                    } catch (Error e) {
                        Idle.add((owned)callback);
                    }
                } else {
                    Idle.add((owned)callback);
                }
            });
            yield;
        }
        return success;
    }
}

}
