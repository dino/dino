using Gdk;
using GLib;
using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;


namespace Dino {
    public interface FileMetadataProvider : Object {
        public abstract bool supports_file(File file);
        public abstract async void fill_metadata(File file, Xep.FileMetadataElement.FileMetadata metadata);
    }

    class GenericFileMetadataProvider: Dino.FileMetadataProvider, Object {
        public bool supports_file(File file) {
            return true;
        }

        public async void fill_metadata(File file, Xep.FileMetadataElement.FileMetadata metadata) {
            FileInfo info = file.query_info("*", FileQueryInfoFlags.NONE);

            metadata.name = info.get_display_name();
            metadata.mime_type = info.get_content_type();
            metadata.size = info.get_size();
            metadata.date = info.get_modification_date_time();

            var checksum_types = new ArrayList<ChecksumType>.wrap(new ChecksumType[] { ChecksumType.SHA256, ChecksumType.SHA512 });
            var file_hashes = yield compute_file_hashes(file, checksum_types);

            metadata.hashes.add(new CryptographicHashes.Hash.with_checksum(ChecksumType.SHA256, file_hashes[ChecksumType.SHA256]));
            metadata.hashes.add(new CryptographicHashes.Hash.with_checksum(ChecksumType.SHA512, file_hashes[ChecksumType.SHA512]));
        }
    }

    public class ImageFileMetadataProvider: Dino.FileMetadataProvider, Object {
        public bool supports_file(File file) {
            string mime_type = file.query_info("*", FileQueryInfoFlags.NONE).get_content_type();
            return Dino.Util.is_pixbuf_supported_mime_type(mime_type);
        }

        private const int[] THUMBNAIL_DIMS = { 1, 2, 3, 4, 8 };
        private const string IMAGE_TYPE = "png";
        private const string MIME_TYPE = "image/png";

        public async void fill_metadata(File file, Xep.FileMetadataElement.FileMetadata metadata) {
            Pixbuf pixbuf = new Pixbuf.from_stream(yield file.read_async());
            metadata.width = pixbuf.get_width();
            metadata.height = pixbuf.get_height();
            float ratio = (float)metadata.width / (float) metadata.height;

            int thumbnail_width = -1;
            int thumbnail_height = -1;
            float diff = float.INFINITY;
            for (int i = 0; i < THUMBNAIL_DIMS.length; i++) {
                int test_width = THUMBNAIL_DIMS[i];
                int test_height = THUMBNAIL_DIMS[THUMBNAIL_DIMS.length - 1 - i];
                float test_ratio = (float)test_width / (float)test_height;
                float test_diff = (test_ratio - ratio).abs();
                if (test_diff < diff) {
                    thumbnail_width = test_width;
                    thumbnail_height = test_height;
                    diff = test_diff;
                }
            }

            Pixbuf thumbnail_pixbuf = pixbuf.scale_simple(thumbnail_width, thumbnail_height, InterpType.BILINEAR);
            uint8[] buffer;
            thumbnail_pixbuf.save_to_buffer(out buffer, IMAGE_TYPE);
            var thumbnail = new Xep.JingleContentThumbnails.Thumbnail();
            thumbnail.data = new Bytes.take(buffer);
            thumbnail.media_type = MIME_TYPE;
            thumbnail.width = thumbnail_width;
            thumbnail.height = thumbnail_height;
            metadata.thumbnails.add(thumbnail);
        }
    }
}

