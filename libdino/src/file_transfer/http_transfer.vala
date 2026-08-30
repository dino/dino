using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino {

    public class HttpFileSlot : FileSendData {
        public string url_down { get; set; }
        public string url_up { get; set; }
        public HashMap<string, string> headers { get; set; }
    }

    public class HttpFileTransfers : Object {

        private StreamInteractor stream_interactor;
        private Dino.Database dino_db;
        private Soup.Session session;
        private HttpFileProvider http_file_provider;
        private HttpFileSender http_file_sender;
        public static Regex http_url_regex = /^https?:\/\/([^\s#]*)$/; // Spaces are invalid in URLs and we can't use fragments for downloads
        public static Regex omemo_url_regex = /^aesgcm:\/\/(.*)#(([A-Fa-f0-9]{2}){48}|([A-Fa-f0-9]{2}){44})$/;
        public HashMap<Account, long> max_file_sizes = new HashMap<Account, long>(Account.hash_func, Account.equals_func);

        public FileManager fm {
            owned get { return stream_interactor.get_module(FileManager.IDENTITY); }
            private set {}
        }

        public HttpFileTransfers(StreamInteractor stream_interactor, Dino.Database dino_db) {
            this.stream_interactor = stream_interactor;
            this.dino_db = dino_db;
            this.session = new Soup.Session();
            this.http_file_provider = new HttpFileProvider(this, stream_interactor);
            this.http_file_sender = new HttpFileSender(stream_interactor, this);
            fm.add_provider(http_file_provider);
            fm.add_sender(http_file_sender);

            session.user_agent = @"Dino/$(Dino.get_short_version()) ";

            stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        }

        public HttpFileReceiveData? get_file_receive_data(FileTransfer file_transfer) {
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

        public async InputStream download(FileTransfer file_transfer, HttpFileReceiveData receive_data, int64 file_size = -1) throws IOError {
            var get_message = new Soup.Message("GET", receive_data.url);

            string transfer_host = Uri.parse(receive_data.url, UriFlags.NONE).get_host();
            get_message.accept_certificate.connect((peer_cert, errors) => { return ConnectionManager.on_invalid_certificate(transfer_host, peer_cert, errors); });
            InputStream stream = yield session.send_async(get_message, GLib.Priority.LOW, file_transfer.cancellable);
            if (get_message.status_code != 200) {
                try { stream.close(); } catch (Error e) {}
                throw new IOError.FAILED("HTTP status code %u".printf(get_message.status_code));
            }

            if (file_size != -1) {
                return new LimitInputStream(stream, file_size);
            } else {
                return stream;
            }
        }

        public bool try_parse_http_transfer(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            string? oob_url = Xmpp.Xep.OutOfBandData.get_url_from_message(stanza);
            bool normal_file = oob_url != null && oob_url == message.body && HttpFileTransfers.http_url_regex.match(message.body);
            bool omemo_file = HttpFileTransfers.omemo_url_regex.match(message.body);
            if (normal_file || omemo_file) {
                http_file_provider.on_file_message(message, conversation);
                return true;
            }
            return false;
        }

        public async HttpFileSlot? request_upload_slot(Account account, string file_name, int64 file_size, FileContentType file_content_type) throws FileSendError {
            HttpFileSlot upload_slot = new HttpFileSlot();
            if (upload_slot == null) return null;

            Xmpp.XmppStream? stream = stream_interactor.get_stream(account);
            if (stream == null) return null;

            try {
                var slot_result = yield stream_interactor.module_manager.get_module(account, Xmpp.Xep.HttpFileUpload.Module.IDENTITY).request_slot(stream, file_name, file_size, file_content_type);
                upload_slot.url_down = slot_result.url_get;
                upload_slot.url_up = slot_result.url_put;
                upload_slot.headers = slot_result.headers;
            } catch (Xep.HttpFileUpload.HttpFileTransferError e) {
                throw new FileSendError.UPLOAD_FAILED("Http file upload XMPP error: %s".printf(e.message));
            }

            return upload_slot;
        }

        public async void upload(FileTransfer file_transfer, string upload_url, HashMap<string, string> header_fields, int64 upload_size) throws FileSendError {
            Xmpp.XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
            if (stream == null) return;

            var put_message = new Soup.Message("PUT", upload_url);

            string transfer_host = Uri.parse(upload_url, UriFlags.NONE).get_host();
            put_message.accept_certificate.connect((peer_cert, errors) => { return ConnectionManager.on_invalid_certificate(transfer_host, peer_cert, errors); });
            put_message.set_request_body(file_transfer.content_type.get_mime_type(), file_transfer.input_stream, (ssize_t) upload_size);

            foreach (var entry in header_fields) {
                put_message.request_headers.append(entry.key, entry.value);
            }
            try {
                yield session.send_async(put_message, GLib.Priority.LOW, file_transfer.cancellable);

                if (put_message.status_code < 200 || put_message.status_code >= 300) {
                    throw new FileSendError.UPLOAD_FAILED("HTTP status code %s".printf(put_message.status_code.to_string()));
                }
            } catch (Error e) {
                throw new FileSendError.UPLOAD_FAILED("HTTP upload error: %s".printf(e.message));
            }
        }

        /** @param use_conversation_encryption With OpenPGP, the file on the server is encrypted and the file transfer is safe even if the message is not encrypted.
         *                                     With OMEMO, the decryption key is part of the message, thus it has to be encrypted.
         */
        public void send_http_file_message(Conversation conversation, FileTransfer file_transfer, string download_url, bool use_conversation_encryption = true) {
            Entities.Message message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(download_url, conversation);
            file_transfer.info = message.id.to_string();

            message.encryption = use_conversation_encryption ? conversation.encryption : Encryption.NONE;
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(message, conversation);
        }

        public async FileMeta request_meta_data(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError {
            HttpFileReceiveData? http_receive_data = receive_data as HttpFileReceiveData;
            if (http_receive_data == null) return file_meta;

            var head_message = new Soup.Message("HEAD", http_receive_data.url);
            head_message.request_headers.append("Accept-Encoding", "identity");
            string transfer_host = Uri.parse(http_receive_data.url, UriFlags.NONE).get_host();
            head_message.accept_certificate.connect((peer_cert, errors) => { return ConnectionManager.on_invalid_certificate(transfer_host, peer_cert, errors); });

            try {
                yield session.send_async(head_message, GLib.Priority.LOW, null);
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

        private void on_stream_negotiated(Account account, XmppStream stream) {
            stream_interactor.module_manager.get_module(account, Xmpp.Xep.HttpFileUpload.Module.IDENTITY).feature_available.connect((stream, max_file_size) => {
                max_file_sizes[account] = max_file_size;
                http_file_sender.upload_available(account);
            });
        }

        public string extract_file_name_from_url(string url) {
            string ret = url;
            if (ret.contains("#")) {
                ret = ret.substring(0, ret.last_index_of("#"));
            }
            ret = Uri.unescape_string(ret.substring(ret.last_index_of("/") + 1));
            return ret;
        }
    }

    public class HttpFileProvider : Dino.FileProvider, Object {

        private HttpFileTransfers http_ft;
        private StreamInteractor stream_interactor;

        public HttpFileProvider(HttpFileTransfers http_ft, StreamInteractor stream_interactor) {
            this.http_ft = http_ft;
            this.stream_interactor = stream_interactor;
        }

        public async FileMeta get_meta_info(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError {
            return yield http_ft.request_meta_data(file_transfer, receive_data, file_meta);
        }

        public Encryption get_encryption(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) {
            return Encryption.NONE;
        }

        public async InputStream download(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws IOError {
            return yield http_ft.download(file_transfer, (HttpFileReceiveData)receive_data, file_transfer.size);
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

            file_meta.file_name = http_ft.extract_file_name_from_url(message.body);

            file_meta.message = message;

            return file_meta;
        }

        public FileReceiveData? get_file_receive_data(FileTransfer file_transfer) {
            return  http_ft.get_file_receive_data(file_transfer);
        }

        public int get_id() { return 0; }

        public void on_file_message(Entities.Message message, Conversation conversation) {
            var additional_info = message.id.to_string();

            var receive_data = new HttpFileReceiveData();
            receive_data.url = message.body;

            var file_meta = new HttpFileMeta();
            file_meta.file_name = http_ft.extract_file_name_from_url(message.body);
            file_meta.message = message;

            file_incoming(additional_info, message.from, message.time, message.local_time, conversation, receive_data, file_meta);
        }
    }

    public class HttpFileSender : FileSender, Object {
        private StreamInteractor stream_interactor;
        private HttpFileTransfers http_ft;

        public HttpFileSender(StreamInteractor stream_interactor, HttpFileTransfers http_ft) {
            this.http_ft = http_ft;
        }

        public async FileSendData? prepare_send_file(Conversation conversation, FileTransfer file_transfer, FileMeta file_meta) throws FileSendError {
            HttpFileSendData send_data = new HttpFileSendData();
            if (send_data == null) return null;

            try {
                var slot_result = yield http_ft.request_upload_slot(conversation.account, file_transfer.server_file_name, file_meta.size, file_transfer.content_type);
                send_data.url_down = slot_result.url_down;
                send_data.url_up = slot_result.url_up;
                send_data.headers = slot_result.headers;
            } catch (Xep.HttpFileUpload.HttpFileTransferError e) {
                throw new FileSendError.UPLOAD_FAILED("Http file upload XMPP error: %s".printf(e.message));
            }

            return send_data;
        }

        public async void send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) throws FileSendError {
            HttpFileSendData http_file_send_data = file_send_data as HttpFileSendData;
            yield http_ft.upload(file_transfer, http_file_send_data.url_up, http_file_send_data.headers, file_meta.size);

            http_ft.send_http_file_message(conversation, file_transfer, http_file_send_data.url_down, true);
        }

        public async bool can_send(Conversation conversation, FileTransfer file_transfer) {
            if (!http_ft.max_file_sizes.has_key(conversation.account)) return false;

            return file_transfer.size < http_ft.max_file_sizes[conversation.account];
        }

        public async long get_file_size_limit(Conversation conversation) {
            long? max_size = http_ft.max_file_sizes[conversation.account];
            if (max_size != null) {
                return max_size;
            }
            return -1;
        }

        public async bool can_encrypt(Conversation conversation, FileTransfer file_transfer) {
            return false;
        }

        public async bool is_upload_available(Conversation conversation) {
            return http_ft.max_file_sizes.has_key(conversation.account);
        }

        public int get_id() { return 0; }

        public float get_priority() { return 100; }
    }
}
