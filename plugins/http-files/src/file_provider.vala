using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.HttpFiles {

public class FileProvider : Dino.FileProvider, Object {

    private StreamInteractor stream_interactor;
    private Dino.Database dino_db;
    private Soup.Session session;
    private static Regex http_url_regex = /^https?:\/\/([^\s#]*)$/; // Spaces are invalid in URLs and we can't use fragments for downloads
    private static Regex omemo_url_regex = /^aesgcm:\/\/(.*)#(([A-Fa-f0-9]{2}){48}|([A-Fa-f0-9]{2}){44})$/;

    public FileProvider(StreamInteractor stream_interactor, Dino.Database dino_db) {
        this.stream_interactor = stream_interactor;
        this.dino_db = dino_db;
        this.session = new Soup.Session();

        session.user_agent = @"Dino/$(Dino.get_short_version()) ";
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new ReceivedMessageListener(this));
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "STORE" };
        public override string action_group { get { return "MESSAGE_REINTERPRETING"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private FileProvider outer;
        private StreamInteractor stream_interactor;

        public ReceivedMessageListener(FileProvider outer) {
            this.outer = outer;
            this.stream_interactor = outer.stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (Xep.StatelessFileSharing.get_file_shares(stanza) != null || Xep.StatelessFileSharing.get_source_attachments(stanza) != null) {
                return false;
            }

            string? oob_url = Xmpp.Xep.OutOfBandData.get_url_from_message(stanza);
            bool normal_file = oob_url != null && oob_url == message.body && FileProvider.http_url_regex.match(message.body);
            bool omemo_file = FileProvider.omemo_url_regex.match(message.body);
            if (normal_file || omemo_file) {
                outer.on_file_message(message, conversation);
                return true;
            }
            return false;
        }
    }

    private void on_file_message(Entities.Message message, Conversation conversation) {
        var additional_info = message.id.to_string();

        var receive_data = new HttpFileReceiveData();
        receive_data.url = message.body;

        var file_meta = new HttpFileMeta();
        file_meta.file_name = extract_file_name_from_url(message.body);
        file_meta.message = message;

        file_incoming(additional_info, message.from, message.time, message.local_time, conversation, receive_data, file_meta);
    }

    public async FileMeta get_meta_info(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError {
        HttpFileReceiveData? http_receive_data = receive_data as HttpFileReceiveData;
        if (http_receive_data == null) return file_meta;

        var head_message = new Soup.Message("HEAD", http_receive_data.url);
        head_message.request_headers.append("Accept-Encoding", "identity");

#if SOUP_3_0
        string transfer_host = Uri.parse(http_receive_data.url, UriFlags.NONE).get_host();
        head_message.accept_certificate.connect((peer_cert, errors) => { return ConnectionManager.on_invalid_certificate(transfer_host, peer_cert, errors); });
#endif

        try {
#if SOUP_3_0
            yield session.send_async(head_message, GLib.Priority.LOW, null);
#else
            yield session.send_async(head_message, null);
#endif
        } catch (Error e) {
            throw new FileReceiveError.GET_METADATA_FAILED("HEAD request failed");
        }

        string? content_type = null, content_length = null;
        head_message.response_headers.foreach((name, val) => {
            if (name.down() == "content-type") content_type = val;
            if (name.down() == "content-length") content_length = val;
        });
        file_meta.content_type = new FileContentType.from_mime_type(content_type);
        if (content_length != null) {
            file_meta.size = int64.parse(content_length);
        }

        return file_meta;
    }

    public Encryption get_encryption(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) {
        return Encryption.NONE;
    }

    public async InputStream download(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws IOError {
        HttpFileReceiveData? http_receive_data = receive_data as HttpFileReceiveData;
        if (http_receive_data == null) assert(false);

        var get_message = new Soup.Message("GET", http_receive_data.url);

#if SOUP_3_0
        string transfer_host = Uri.parse(http_receive_data.url, UriFlags.NONE).get_host();
        get_message.accept_certificate.connect((peer_cert, errors) => { return ConnectionManager.on_invalid_certificate(transfer_host, peer_cert, errors); });
#endif

#if SOUP_3_0
        InputStream stream = yield session.send_async(get_message, GLib.Priority.LOW, file_transfer.cancellable);
#else
        InputStream stream = yield session.send_async(get_message, file_transfer.cancellable);
#endif
        if (file_meta.size != -1) {
            return new LimitInputStream(stream, file_meta.size);
        } else {
            return stream;
        }
    }

    public FileMeta get_file_meta(FileTransfer file_transfer) throws FileReceiveError {
        if (file_transfer.provider == FileManager.SFS_PROVIDER_ID) {
            var file_meta = new HttpFileMeta();
            file_meta.size = file_transfer.size;
            file_meta.content_type = file_transfer.content_type;
            file_meta.file_name = file_transfer.file_name;
            file_meta.message = null;
            return file_meta;
        }

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(file_transfer.counterpart.bare_jid, file_transfer.account);
        if (conversation == null) throw new FileReceiveError.GET_METADATA_FAILED("No conversation");

        Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(int.parse(file_transfer.info), conversation);
        if (message == null) throw new FileReceiveError.GET_METADATA_FAILED("No message");

        var file_meta = new HttpFileMeta();
        file_meta.size = file_transfer.size;
        file_meta.content_type = file_transfer.content_type;

        file_meta.file_name = extract_file_name_from_url(message.body);

        file_meta.message = message;

        return file_meta;
    }

    public FileReceiveData? get_file_receive_data(FileTransfer file_transfer) {
        if (file_transfer.provider == FileManager.SFS_PROVIDER_ID) {
            if (!file_transfer.sfs_sources.is_empty) {
                var http_source = file_transfer.sfs_sources.get(0) as Xep.StatelessFileSharing.HttpSource;
                if (http_source != null) {
                    var receive_data = new HttpFileReceiveData();
                    receive_data.url = http_source.url;
                    return receive_data;
                }
            }
            return null;
        }

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(file_transfer.counterpart.bare_jid, file_transfer.account);
        if (conversation == null) return null;

        Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(int.parse(file_transfer.info), conversation);
        if (message == null) return null;

        var receive_data = new HttpFileReceiveData();
        receive_data.url = message.body;

        return receive_data;
    }

    private string extract_file_name_from_url(string url) {
        string ret = url;
        if (ret.contains("#")) {
            ret = ret.substring(0, ret.last_index_of("#"));
        }
        ret = Uri.unescape_string(ret.substring(ret.last_index_of("/") + 1));
        return ret;
    }

    public int get_id() { return 0; }
}

}
