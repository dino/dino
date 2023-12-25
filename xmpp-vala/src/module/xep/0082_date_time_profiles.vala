namespace Xmpp.Xep.DateTimeProfiles {

public DateTime? parse_string(string time_string) {
     return new DateTime.from_iso8601(time_string, null);
}

public string to_datetime(DateTime time) {
     return time.to_utc().format_iso8601().to_string();
}

}
