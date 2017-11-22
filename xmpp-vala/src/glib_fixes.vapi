[CCode (cprefix = "G", gir_namespace = "Gio", gir_version = "2.0", lower_case_cprefix = "g_")]
namespace GLibFixes {

    [CCode (cheader_filename = "gio/gio.h", type_id = "g_resolver_get_type ()")]
    public class Resolver : GLib.Object {
        [CCode (has_construct_function = false)]
        protected Resolver();

        [Version (since = "2.22")]
        public static Resolver get_default();

        [Version (since = "2.22")]
        public virtual string lookup_by_address(GLib.InetAddress address, GLib.Cancellable? cancellable = null) throws GLib.Error ;

        [Version (since = "2.22")]
        public virtual async string lookup_by_address_async(GLib.InetAddress address, GLib.Cancellable? cancellable = null) throws GLib.Error ;

        [Version (since = "2.22")]
        public virtual GLib.List<GLib.InetAddress> lookup_by_name(string hostname, GLib.Cancellable? cancellable = null) throws GLib.Error ;

        [Version (since = "2.22")]
        public virtual async GLib.List<GLib.InetAddress> lookup_by_name_async(string hostname, GLib.Cancellable? cancellable = null) throws GLib.Error ;

        [Version (since = "2.34")]
        public virtual GLib.List<GLib.Variant> lookup_records(string rrname, GLib.ResolverRecordType record_type, GLib.Cancellable? cancellable = null) throws GLib.Error ;

        [Version (since = "2.34")]
        public virtual async GLib.List<GLib.Variant> lookup_records_async(string rrname, GLib.ResolverRecordType record_type, GLib.Cancellable? cancellable = null) throws GLib.Error ;

        [Version (since = "2.22")]
        public virtual GLib.List<GLib.SrvTarget> lookup_service(string service, string protocol, string domain, GLib.Cancellable? cancellable = null) throws GLib.Error ;

        [CCode (finish_vfunc_name = "lookup_service_finish", vfunc_name = "lookup_service_async")]
        public async GLib.List<GLib.SrvTarget> lookup_service_async (string service, string protocol, string domain, GLib.Cancellable? cancellable = null) throws GLib.Error;

        [Version (since = "2.22")]
        public void set_default();

        public virtual signal void reload ();
    }

}
