using Dino.Entities;
using Xmpp;
using Gee;

namespace Dino.Plugins.HttpFiles {

public class HttpFileSender : FileSender, Object {
    private StreamInteractor stream_interactor;
    private Database db;
    private Soup.Session session;
    private HashMap<Account, long> max_file_sizes = new HashMap<Account, long>(Account.hash_func, Account.equals_func);

    public HttpFileSender(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.session = new Soup.Session();

        session.user_agent = @"Dino/$(Dino.get_short_version()) ";
        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.get_module(MessageProcessor.IDENTITY).build_message_stanza.connect(check_add_sfs_element);
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

        bool can_reference_element = !conversation.type_.is_muc_semantic() || stream_interactor.get_module(EntityInfo.IDENTITY).has_feature_cached(conversation.account, conversation.counterpart, Xep.UniqueStableStanzaIDs.NS_URI);

        // Share unencrypted files via SFS (only if we'll be able to reference messages)
        if (conversation.encryption == Encryption.NONE && can_reference_element) {
            // Announce the file share
            Entities.Message file_share_message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(null, conversation);
            file_transfer.info = file_share_message.id.to_string();
            file_transfer.file_sharing_id = Xmpp.random_uuid();
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(file_share_message, conversation);

            // Upload file
            yield upload(file_transfer, send_data, file_meta);

            // Wait until we know the server id of the file share message (in MUCs; we get that from the reflected message)
            if (conversation.type_.is_muc_semantic()) {
                if (file_share_message.server_id == null) {
                    ulong server_id_notify_id = file_share_message.notify["server-id"].connect(() => {
                        Idle.add(send_file.callback);
                    });
                    yield;
                    file_share_message.disconnect(server_id_notify_id);
                }
            }

            file_transfer.sfs_sources.add(new Xep.StatelessFileSharing.HttpSource() { url=send_data.url_down } );

            // Send source attachment
            MessageStanza stanza = new MessageStanza() { to = conversation.counterpart, type_ = conversation.type_ == GROUPCHAT ? MessageStanza.TYPE_GROUPCHAT : MessageStanza.TYPE_CHAT };
            stanza.body = send_data.url_down;
            Xep.OutOfBandData.add_url_to_message(stanza, send_data.url_down);
            var sources = new ArrayList<Xep.StatelessFileSharing.Source>();
            sources.add(new Xep.StatelessFileSharing.HttpSource() { url = send_data.url_down });
            string attach_to_id = MessageStorage.get_reference_id(file_share_message);
            Xep.StatelessFileSharing.set_sfs_attachment(stanza, attach_to_id, file_transfer.file_sharing_id, sources);

            var stream = stream_interactor.get_stream(conversation.account);
            if (stream == null) throw new FileSendError.UPLOAD_FAILED("No stream");

            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, stanza);
        }
        // Share encrypted files without SFS
        else {
            yield upload(file_transfer, send_data, file_meta);

            Entities.Message message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(send_data.url_down, conversation);
            file_transfer.info = message.id.to_string();

            message.encryption = send_data.encrypt_message ? conversation.encryption : Encryption.NONE;
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(message, conversation);
        }
    }

    public async bool can_send(Conversation conversation, FileTransfer file_transfer) {
        if (!max_file_sizes.has_key(conversation.account)) return false;

        return file_transfer.size < max_file_sizes[conversation.account];
    }

    public async long get_file_size_limit(Conversation conversation) {
        long? max_size = max_file_sizes[conversation.account];
        if (max_size != null) {
            return max_size;
        }
        return -1;
    }

    public async bool can_encrypt(Conversation conversation, FileTransfer file_transfer) {
        return false;
    }

    public async bool is_upload_available(Conversation conversation) {
        lock (max_file_sizes) {
            return max_file_sizes.has_key(conversation.account);
        }
    }

#if !SOUP_3_0
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
#endif

    private async void upload(FileTransfer file_transfer, HttpFileSendData file_send_data, FileMeta file_meta) throws FileSendError {
        Xmpp.XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        if (stream == null) return;

        var put_message = new Soup.Message("PUT", file_send_data.url_up);

#if SOUP_3_0
        string transfer_host = Uri.parse(file_send_data.url_up, UriFlags.NONE).get_host();
        put_message.accept_certificate.connect((peer_cert, errors) => { return ConnectionManager.on_invalid_certificate(transfer_host, peer_cert, errors); });
        put_message.set_request_body(file_meta.mime_type, file_transfer.input_stream, (ssize_t) file_meta.size);
#else
        put_message.request_headers.set_content_type(file_meta.mime_type, null);
        put_message.request_headers.set_content_length(file_meta.size);
        put_message.request_body.set_accumulate(false);
        put_message.wrote_headers.connect(() => transfer_more_bytes(file_transfer.input_stream, put_message.request_body));
        put_message.wrote_chunk.connect(() => transfer_more_bytes(file_transfer.input_stream, put_message.request_body));
#endif
        foreach (var entry in file_send_data.headers.entries) {
            put_message.request_headers.append(entry.key, entry.value);
        }
        try {
#if SOUP_3_0
            yield session.send_async(put_message, GLib.Priority.LOW, file_transfer.cancellable);
#else
            yield session.send_async(put_message, file_transfer.cancellable);
#endif
            if (put_message.status_code < 200 || put_message.status_code >= 300) {
                throw new FileSendError.UPLOAD_FAILED("HTTP status code %s".printf(put_message.status_code.to_string()));
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

    private void check_add_sfs_element(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        if (message.encryption != Encryption.NONE) return;

        FileTransfer? file_transfer = stream_interactor.get_module(FileTransferStorage.IDENTITY).get_file_by_message_id(message.id, conversation);
        if (file_transfer == null) return;

        Xep.StatelessFileSharing.set_sfs_element(message_stanza, file_transfer.file_sharing_id, file_transfer.file_metadata, file_transfer.sfs_sources);

        Xep.MessageProcessingHints.set_message_hint(message_stanza, Xep.MessageProcessingHints.HINT_STORE);
    }

    public int get_id() { return 0; }

    public float get_priority() { return 100; }
}

}
