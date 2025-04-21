namespace Xmpp {

    // FileInfo.get_content_type() returns a content type. On Linux, that's the same as the mime type, but on Windows and MacOS it's not.
    // Since content type and mime type are both strings, this util class introduces some type checks around that.
    public class FileContentType {
        string content_type = null;

        public FileContentType.from_file_info(FileInfo file_info) {
            content_type = file_info.get_content_type();
        }

        public FileContentType.from_mime_type(string mime_type) {
            content_type = ContentType.from_mime_type(mime_type);
        }

        public FileContentType.from_file(File file) {
            FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
            this.from_file_info(file_info);
        }

        public string get_mime_type() {
            return ContentType.get_mime_type(content_type);
        }

        public string? get_generic_icon_name() {
            return ContentType.get_generic_icon_name(content_type);
        }

        public string? get_description() {
            return ContentType.get_description(content_type);
        }

        public bool is_image() {
            return get_mime_type().has_prefix("image");
        }
    }
}