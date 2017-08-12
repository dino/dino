namespace Xmpp.Xep.DateTimeProfiles {

public class Module {
    public Regex DATETIME_REGEX;

    public Module() {
        DATETIME_REGEX = new Regex("""^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.(\d{3}))?(Z|((\+|\-)(\d{2})(:(\d{2}))?))$""");
    }

    public DateTime? parse_string(string time_string) {
        MatchInfo match_info;
        if (DATETIME_REGEX.match(time_string, RegexMatchFlags.ANCHORED, out match_info)) {
            int year = int.parse(match_info.fetch(1));
            int month = int.parse(match_info.fetch(2));
            int day = int.parse(match_info.fetch(3));
            int hour = int.parse(match_info.fetch(4));
            int minute = int.parse(match_info.fetch(5));
            int second = int.parse(match_info.fetch(6));
            DateTime datetime = new DateTime.utc(year, month, day, hour, minute, second);
            if (match_info.fetch(9) != "Z") {
                char plusminus = match_info.fetch(11)[0];
                int tz_hour = int.parse(match_info.fetch(12));
                int tz_minute = int.parse(match_info.fetch(13));
                if (plusminus == '-') {
                    tz_hour *= -1;
                    tz_minute *= -1;
                }
                datetime.add_hours(tz_hour);
                datetime.add_minutes(tz_minute);
            }
            return datetime;
        }
        return null;
    }

public string to_datetime(DateTime time) {
    return time.to_utc().format("%Y-%m-%dT%H:%M:%SZ");
}

}

}
