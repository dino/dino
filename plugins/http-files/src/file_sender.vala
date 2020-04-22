using Dino.Entities;
using Xmpp;
using Gee;

namespace Dino.Plugins.HttpFiles {

public class HttpFileSender : FileSender, Object {
    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Account, long> max_file_sizes = new HashMap<Account, long>(Account.hash_func, Account.equals_func);

    public HttpFileSender(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.get_module(MessageProcessor.IDENTITY).build_message_stanza.connect(check_add_oob);
    }

    public async FileSendData? prepare_send_file(Conversation conversation, FileTransfer file_transfer, FileMeta file_meta) throws FileSendError {
        HttpFileSendData send_data = new HttpFileSendData();
        if (send_data == null) return null;

        Xmpp.XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        if (stream == null) return null;

        try {
            var slot_result = yield stream_interactor.module_manager.get_module(file_transfer.account, Xmpp.Xep.HttpFileUpload.Module.IDENTITY).request_slot(stream, file_transfer.server_file_name, file_meta.size, file_meta.mime_type);
            send_data.url_down = slot_result.url_get;
            send_data.url_up = slot_result.url_put;
            send_data.headers = slot_result.headers;
        } catch (Xep.HttpFileUpload.HttpFileTransferError e) {
            throw new FileSendError.UPLOAD_FAILED("Http file upload XMPP error: %s".printf(e.message));
        }

        return send_data;
    }

    public async void send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) throws FileSendError {
        HttpFileSendData? send_data = file_send_data as HttpFileSendData;
        if (send_data == null) return;

        yield upload(file_transfer, send_data, file_meta);

        file_transfer.info = send_data.url_down; // store the message content temporarily so the message gets filtered out

        Entities.Message message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(send_data.url_down, conversation);

        message.encryption = send_data.encrypt_message ? conversation.encryption : Encryption.NONE;
        stream_interactor.get_module(MessageProcessor.IDENTITY).send_message(message, conversation);

        file_transfer.info = message.id.to_string();

        ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, message.id);
        if (content_item != null) {
            stream_interactor.get_module(ContentItemStore.IDENTITY).set_item_hide(content_item, true);
        }
    }

    public bool can_send(Conversation conversation, FileTransfer file_transfer) {
        if (!max_file_sizes.has_key(conversation.account)) return false;

        return file_transfer.size < max_file_sizes[conversation.account];
    }

    public long get_file_size_limit(Conversation conversation) {
        long? max_size = max_file_sizes[conversation.account];
        if (max_size != null) {
            return max_size;
        }
        return -1;
    }

    public bool can_encrypt(Conversation conversation, FileTransfer file_transfer) {
        return false;
    }

    public bool is_upload_available(Conversation conversation) {
        lock (max_file_sizes) {
            return max_file_sizes.has_key(conversation.account);
        }
    }

    public long get_max_file_size(Account account) {
        lock (max_file_sizes) {
            return max_file_sizes[account];
        }
    }

    private static void transfer_more_bytes(InputStream stream, Soup.MessageBody body) {
        uint8[] bytes = new uint8[4096];
        ssize_t read = stream.read(bytes);
        if (read == 0) {
            body.complete();
            return;
        }
        bytes.length = (int)read;
        body.append_buffer(new Soup.Buffer.take(bytes));
    }

    private async void upload(FileTransfer file_transfer, HttpFileSendData file_send_data, FileMeta file_meta) throws FileSendError {
        Xmpp.XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        if (stream == null) return;

        Soup.Message message = new Soup.Message("PUT", file_send_data.url_up);
        message.request_headers.set_content_type(file_meta.mime_type, null);
        message.request_headers.set_content_length(file_meta.size);
        foreach (var entry in file_send_data.headers.entries) {
            message.request_headers.append(entry.key, entry.value);
        }
        message.request_body.set_accumulate(false);
        message.wrote_headers.connect(() => transfer_more_bytes(file_transfer.input_stream, message.request_body));
        message.wrote_chunk.connect(() => transfer_more_bytes(file_transfer.input_stream, message.request_body));
        Soup.Session session = new Soup.Session();
        try {
            yield session.send_async(message);
            if (message.status_code < 200 || message.status_code >= 300) {
                throw new FileSendError.UPLOAD_FAILED("HTTP status code %s".printf(message.status_code.to_string()));
            }
        } catch (Error e) {
            throw new FileSendError.UPLOAD_FAILED("HTTP upload error: %s".printf(e.message));
        }
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        stream_interactor.module_manager.get_module(account, Xmpp.Xep.HttpFileUpload.Module.IDENTITY).feature_available.connect((stream, max_file_size) => {
            lock (max_file_sizes) {
                max_file_sizes[account] = max_file_size;
            }
            upload_available(account);
        });
    }

    private void check_add_oob(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        if (message.encryption == Encryption.NONE && message_is_file(db, message) && message.body.has_prefix("http")) {
            Xep.OutOfBandData.add_url_to_message(message_stanza, message_stanza.body);
        }
    }

    public int get_id() { return 0; }

    public float get_priority() { return 100; }
}

}
