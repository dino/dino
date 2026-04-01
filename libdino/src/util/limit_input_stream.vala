public class Dino.LimitInputStream : InputStream, PollableInputStream {
    private InputStream inner;
    public int64 max_bytes { public get; private set; }
    public int64 retrieved_bytes { public get; private set; }

    public int64 remaining_bytes { get {
        return max_bytes < 0 ? -1 : max_bytes - retrieved_bytes;
    }}

    public LimitInputStream(InputStream inner, int64 max_bytes) {
            this.inner = inner;
            this.max_bytes = max_bytes;
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
            // Due to https://gitlab.gnome.org/GNOME/libsoup/-/issues/473 and
            // https://gitlab.gnome.org/GNOME/glib-networking/-/issues/20, is_readable() can return false when
            // approaching end of stream even if the stream is readable.
            return remaining_bytes < 65536 || ((PollableInputStream)inner).is_readable();
        }

    private ssize_t check_limit(ssize_t read) throws IOError {
            if (remaining_bytes - (int64) read < 0) throw new IOError.FAILED("Stream length exceeded limit");
            this.retrieved_bytes += read;
            return read;
        }

    public override ssize_t read(uint8[] buffer, Cancellable? cancellable = null) throws IOError {
        if (remaining_bytes == 0) return 0;
            int original_buffer_length = buffer.length;
            if (remaining_bytes != -1 && (int64) buffer.length > remaining_bytes) {
                // Never read more than remaining_bytes by limiting the buffer length
                buffer.length = (int) remaining_bytes;
            }
        ssize_t read_bytes = inner.read(buffer, cancellable);
        this.retrieved_bytes += read_bytes;
        buffer.length = original_buffer_length;
        return read_bytes;
    }

    public override async ssize_t read_async(uint8[]? buffer, int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        if (remaining_bytes == 0) return 0;
        int original_buffer_length = buffer.length;
        if (remaining_bytes != -1 && (int64) buffer.length > remaining_bytes) {
            // Never read more than remaining_bytes by limiting the buffer length
            buffer.length = (int) remaining_bytes;
        }
        ssize_t read_bytes = yield inner.read_async(buffer, io_priority, cancellable);
        this.retrieved_bytes += read_bytes;
        buffer.length = original_buffer_length;
        return read_bytes;
    }

    public ssize_t read_nonblocking_fn(uint8[] buffer) throws Error {
        if (remaining_bytes == 0) return 0;
        if (!is_readable()) throw new IOError.WOULD_BLOCK("Stream is not readable");
        int original_buffer_length = buffer.length;
        if (remaining_bytes != -1 && (int64) buffer.length > remaining_bytes) {
            // Never read more than remaining_bytes by limiting the buffer length
            buffer.length = (int) remaining_bytes;
        }
        ssize_t read_bytes = ((PollableInputStream)inner).read_nonblocking_fn(buffer);
        this.retrieved_bytes += read_bytes;
        buffer.length = original_buffer_length;
        return read_bytes;
    }

    public override bool close(Cancellable? cancellable = null) throws IOError {
        return inner.close(cancellable);
    }

    public override async bool close_async(int io_priority = GLib.Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        return yield inner.close_async(io_priority, cancellable);
    }
}