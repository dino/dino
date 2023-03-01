using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.HttpFiles {

public class FileProvider : Dino.FileProvider, Object {

    private StreamInteractor stream_interactor;
    private Dino.Database dino_db;
    private static Regex http_url_regex = /^https?:\/\/([^\s#]*)$/; // Spaces are invalid in URLs and we can't use fragments for downloads
    private static Regex omemo_url_regex = /^aesgcm:\/\/(.*)#(([A-Fa-f0-9]{2}){48}|([A-Fa-f0-9]{2}){44})$/;

    public FileProvider(StreamInteractor stream_interactor, Dino.Database dino_db) {
        this.stream_interactor = stream_interactor;
        this.dino_db = dino_db;

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

    private class LimitInputStream : InputStream, PollableInputStream {
        InputStream inner;
        int64 remaining_size;

        public LimitInputStream(InputStream inner, int64 max_size) {
            this.inner = inner;
            this.remaining_size = max_size;
        }

        public bool can_poll() {
            return inner is PollableInputStream && ((PollableInputStream)inner).can_poll();
        }

        public PollableSource create_source(Cancellable? cancellable = null) {
            if (!can_poll()) throw new IOError.NOT_SUPPORTED("Stream is not pollable");
            return ((PollableInputStream)inner).create_source(cancellable);
        }

        public bool is_readable() {
            if (!can_poll()) throw new IOError.NOT_SUPPORTED("Stream is not pollable");
            return remaining_size <= 0 || ((PollableInputStream)inner).is_readable();
        }

        private ssize_t check_limit(ssize_t read) throws IOError {
            this.remaining_size -= read;
            if (remaining_size < 0) throw new IOError.FAILED("Stream length exceeded limit");
            return read;
        }

        public override ssize_t read(uint8[] buffer, Cancellable? cancellable = null) throws IOError {
            return check_limit(inner.read(buffer, cancellable));
        }

        public override async ssize_t read_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return check_limit(yield inner.read_async(buffer, io_priority, cancellable));
        }

        public ssize_t read_nonblocking_fn(uint8[] buffer) throws Error {
            if (!is_readable()) throw new IOError.WOULD_BLOCK("Stream is not readable");
            return read(buffer);
        }

        public override bool close(Cancellable? cancellable = null) throws IOError {
            return inner.close(cancellable);
        }

        public override async bool close_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
            return yield inner.close_async(io_priority, cancellable);
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

        var session = new Soup.Session();
        session.user_agent = @"Dino/$(Dino.get_short_version()) ";
        var head_message = new Soup.Message("HEAD", http_receive_data.url);
        head_message.request_headers.append("Accept-Encoding", "identity");

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
        file_meta.mime_type = content_type;
        if (content_length != null) {
            file_meta.size = int64.parse(content_length);
        }

        return file_meta;
    }

    public Encryption get_encryption(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) {
        return Encryption.NONE;
    }

    public async InputStream download(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError {
        HttpFileReceiveData? http_receive_data = receive_data as HttpFileReceiveData;
        if (http_receive_data == null) assert(false);

        var session = new Soup.Session();
        session.user_agent = @"Dino/$(Dino.get_short_version()) ";
        var get_message = new Soup.Message("GET", http_receive_data.url);

        try {
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
        } catch (Error e) {
            throw new FileReceiveError.DOWNLOAD_FAILED("Downloading file error: %s".printf(e.message));
        }
    }

    public FileMeta get_file_meta(FileTransfer file_transfer) throws FileReceiveError {
        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(file_transfer.counterpart.bare_jid, file_transfer.account);
        if (conversation == null) throw new FileReceiveError.GET_METADATA_FAILED("No conversation");

        Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(int.parse(file_transfer.info), conversation);
        if (message == null) throw new FileReceiveError.GET_METADATA_FAILED("No message");

        var file_meta = new HttpFileMeta();
        file_meta.size = file_transfer.size;
        file_meta.mime_type = file_transfer.mime_type;

        file_meta.file_name = extract_file_name_from_url(message.body);

        file_meta.message = message;

        return file_meta;
    }

    public FileReceiveData? get_file_receive_data(FileTransfer file_transfer) {
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
