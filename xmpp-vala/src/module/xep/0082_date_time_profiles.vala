namespace Xmpp.Xep.DateTimeProfiles {

public DateTime? parse_time(string time_string) {
     return new DateTime.from_iso8601(time_string, null);
}

public TimeZone? parse_tzd(string tzd) {
     if (tzd == "Z") return new TimeZone.utc();
     // We support parsing TZD without positive or negative sign prefix for compatibility
     string unprefixed;
     if (tzd.length == 5) {
          unprefixed = tzd;
     } else if (tzd.length == 6 && (tzd.has_prefix("-") || tzd.has_prefix("+"))) {
          unprefixed = tzd.substring(1);
     } else {
          return null;
     }
     int h_offset = unprefixed.substring(0, 2).to_int();
     int m_offset = unprefixed.substring(3, 2).to_int();
     int offset = h_offset * 60 * 60 + m_offset * 60;
     if (tzd.has_prefix("-")) {
          offset = -offset;
     }
     return new TimeZone.offset(offset);
}

public string format_time(DateTime time) {
     return time.to_utc().format_iso8601().to_string();
}

public string format_tzd(DateTime time) {
     TimeSpan utc_offset = time.get_utc_offset();
     if (utc_offset == 0) return "Z";
     int m_offset = (int) (utc_offset / TimeSpan.MINUTE).abs() % 60;
     int h_offset = (int) (utc_offset / TimeSpan.HOUR).abs();
     string prefix = utc_offset < 0 ? "-" : "+";
     return "%s%02d:%02d".printf(prefix, h_offset, m_offset);
}

}
