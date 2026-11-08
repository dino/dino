using Gee;

namespace Xmpp.Xep.MessageStyling {

    public Gee.List<MessageMarkup.Markup> parse(string text) {
        var markups = new ArrayList<MessageMarkup.Markup>();
        parse_markup_rec(markups, 0, text, true, true);
        return markups;
    }

    public static void parse_markup_rec(ArrayList<MessageMarkup.Markup> result_markups, int offset, string s_, bool parse_text_markup, bool parse_quotes) {
        string s = s_;

        if (parse_quotes) {
            string gt = ">";
            Regex quote_regex = new Regex("((?<=\n)" + gt + ".*(\n|$))|(^" + gt + ".*(\n|$))", RegexCompileFlags.CASELESS);
            MatchInfo quote_match_info;
            quote_regex.match(s, 0, out quote_match_info);
            if (quote_match_info.matches()) {
                int start, end;
                quote_match_info.fetch_pos(0, out start, out end);

                result_markups.add(new Xep.MessageMarkup.BlockQuote() {
                    start_char = offset + start,
                    end_char = offset + end
                });

                parse_markup_rec(result_markups, offset, s[0:start], parse_text_markup, parse_quotes);
                parse_markup_rec(result_markups, offset + start + gt.length, s[start + gt.length:end], parse_text_markup, parse_quotes);
                parse_markup_rec(result_markups, offset + end, s[end:s.length], parse_text_markup, parse_quotes);
                return;
            }
        }

        if (parse_text_markup) {
            string[] markup_strings = new string[]{"`", "_", "*", "~"};
            Xep.MessageMarkup.SpanType[] span_types = new Xep.MessageMarkup.SpanType[]{
                Xep.MessageMarkup.SpanType.CODE,
                Xep.MessageMarkup.SpanType.EMPHASIS,
                Xep.MessageMarkup.SpanType.STRONG_EMPHASIS,
                Xep.MessageMarkup.SpanType.DELETED
            };

            for (int i = 0; i < markup_strings.length; i++) {
                string markup_esc = Regex.escape_string(markup_strings[i]);
                try {
                    Regex regex = new Regex("(^|\\s)" + markup_esc + "(\\S|\\S.*?\\S)" + markup_esc, RegexCompileFlags.CASELESS);
                    MatchInfo match_info;
                    regex.match(s, 0, out match_info);
                    if (match_info.matches()) {
                        int start, end;
                        match_info.fetch_pos(2, out start, out end);

                        var used_span_types = new ArrayList<Xep.MessageMarkup.SpanType>();
                        used_span_types.add(span_types[i]);
                        result_markups.add(new Xep.MessageMarkup.Span() {
                            types = used_span_types,
                            start_char = offset + start,
                            end_char = offset + end
                        });

                        parse_markup_rec(result_markups, offset, s[0:start-1], parse_text_markup, false);
                        parse_markup_rec(result_markups, offset + start, s[start:end], parse_text_markup, false);
                        parse_markup_rec(result_markups, offset + end + 1, s[end+1:s.length], parse_text_markup, false);
                        return;
                    }
                } catch (RegexError e) {
                    assert_not_reached();
                }
            }
        }

        return;
    }
}
