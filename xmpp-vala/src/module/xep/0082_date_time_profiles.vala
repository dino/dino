namespace Xmpp.Xep.DateTimeProfiles {

public DateTime? parse_string(string time_string) {
    // TODO with glib >= 2.56
    // return new DateTime.from_iso8601(time_string, null);

    TimeVal time_val = TimeVal();
    if (time_val.from_iso8601(time_string)) {
        return new DateTime.from_unix_utc(time_val.tv_sec);
    }
    return null;

}


public string to_datetime(DateTime time) {
    // TODO with glib >= 2.62
    // return time.to_utc().format_iso8601().to_string();

    return time.to_utc().format("%Y-%m-%dT%H:%M:%SZ");
}

}
