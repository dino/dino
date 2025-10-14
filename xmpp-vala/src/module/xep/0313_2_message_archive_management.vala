using Gee;
using Xmpp.Xep;

namespace Xmpp.MessageArchiveManagement.V2 {

    public class MamQueryParams {
        public bool use_ns2_extended = false;

        public string query_id = Xmpp.random_uuid();
        public Jid mam_server { get; set; }
        public Jid? with { get; set; }
        // "The 'start' field is used to filter out messages before a certain date/time."
        public DateTime? start { get; set; }
        // "the 'end' field is used to exclude from the results messages after a certain point in time"
        public DateTime? end { get; set; }
        public string? start_id { get; set; }
        public string? end_id { get; set; }

        public MamQueryParams.query_latest(Jid mam_server, DateTime? latest_known_time, string? latest_known_id) {
            this.mam_server = mam_server;
            this.start = latest_known_time;
            this.start_id = latest_known_id;
        }

        public MamQueryParams.query_between(Jid mam_server,
                                            DateTime? earliest_time, string? earliest_id,
                                            DateTime? latest_time, string? latest_id) {
            this.mam_server = mam_server;
            this.start = earliest_time;
            this.start_id = earliest_id;
            this.end = latest_time;
            this.end_id = latest_id;
        }

        public MamQueryParams.query_before(Jid mam_server, DateTime? earliest_time, string? earliest_id) {
            this.mam_server = mam_server;
            this.end = earliest_time;
            this.end_id = earliest_id;
        }
    }

    private StanzaNode create_base_query(XmppStream stream, MamQueryParams mam_params) {
        var fields = new ArrayList<DataForms.DataForm.Field>();

        if (mam_params.with != null) {
            DataForms.DataForm.Field field = new DataForms.DataForm.Field() { var="with" };
            field.set_value_string(mam_params.with.to_string());
            fields.add(field);
        }
        if (mam_params.start != null) {
            DataForms.DataForm.Field field = new DataForms.DataForm.Field() { var="start" };
            field.set_value_string(DateTimeProfiles.to_datetime(mam_params.start));
            fields.add(field);
        }
        if (mam_params.end != null && mam_params.end_id == null && !mam_params.use_ns2_extended) {
            DataForms.DataForm.Field field = new DataForms.DataForm.Field() { var="end" };
            field.set_value_string(DateTimeProfiles.to_datetime(mam_params.end));
            fields.add(field);
        }

        return MessageArchiveManagement.create_base_query(stream, mam_params.query_id, fields);
    }

    public async QueryResult query_archive(XmppStream stream, MamQueryParams mam_params, Cancellable? cancellable = null) {
        var query_node = create_base_query(stream, mam_params);
        if (!mam_params.use_ns2_extended) {
            query_node.put_node(ResultSetManagement.create_set_rsm_node_before(mam_params.end_id));
        }

        return yield MessageArchiveManagement.query_archive(stream, mam_params.mam_server, query_node, cancellable);
    }

    public async QueryResult page_through_results(XmppStream stream, MamQueryParams mam_params, QueryResult prev_result, Cancellable? cancellable = null) {
        var query_node = create_base_query(stream, mam_params);
        query_node.put_node(ResultSetManagement.create_set_rsm_node_before(prev_result.first));

        return yield MessageArchiveManagement.query_archive(stream, mam_params.mam_server, query_node, cancellable);
    }
}

