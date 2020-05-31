// Comparing between two strings based on python's difflib SequenceMatcher
// https://github.com/python/cpython/blob/master/Lib/difflib.py
// which is based on an algorithm published in the late 1980's by Ratcliff and Obershelp under the name "gestalt pattern matching".
// https://en.wikipedia.org/wiki/Gestalt_Pattern_Matching

using Gee;

namespace  Dino { 
    
    class Match {
        public int old_index { get; set; }
        public int new_index { get; set; }
        public int length { get; set; }
    }

    class MessageSlice {
        public int old_lo { get; set; }
        public int old_hi { get; set; }
        public int new_lo { get; set; }
        public int new_hi { get; set; }
    }

    class MessageComparision : Object {

        public string old_message;
        public string new_message;

        private HashMap<string, ArrayList<int>> message_to_indices = new HashMap<string, ArrayList<int>>();


        public MessageComparision(string old_message, string new_message) {

            this.old_message = old_message;
            this.new_message = new_message;
        }

        private void convert_to_indices(string message){

            unichar c;
            for (int i = 0; message.get_next_char (ref i, out c);) {

                if (message_to_indices.has_key(c.to_string())) {
                    message_to_indices[c.to_string()].add(i-1);  
                } else {
                    message_to_indices[c.to_string()] = new ArrayList<int>();
                    message_to_indices[c.to_string()].add(i-1);
                }
            }
        }

        public Match find_longest_match(MessageSlice message_slice){

            string old_message = this.old_message;
            string new_message = this.new_message;
            HashMap<string, ArrayList<int>> message_to_indices = this.message_to_indices;


            int besti = message_slice.old_lo;
            int bestj = message_slice.new_lo;
            int bestsize = 0;
            int k;

            HashMap<int, int> index_to_len = new HashMap<int, int>();
            HashMap<int, int> new_index_to_len;


            for (int i=message_slice.old_lo; i<message_slice.old_hi; i++) {

                string curr_char = old_message.get_char(old_message.index_of_nth_char(i)).to_string();

                new_index_to_len = new HashMap<int, int>();

                ArrayList<int>? indices =  message_to_indices.has_key(curr_char) ? message_to_indices[curr_char] : null;

                foreach(int index in indices) {
                    if (index < message_slice.new_lo) {
                        continue;
                    }

                    if (index >= message_slice.new_hi) {
                        break;
                    }
                    
                    if(index_to_len.has_key(index-1)) {
                        k = index_to_len[index-1] + 1;
                        new_index_to_len[index] = k;
                    } else {
                        k = 1;
                        new_index_to_len[index] = k;
                    }
                    //  k = new_index_to_len[index] = index_to_len.has_key(index-1) ? index_to_len[index-1] + 1 : 1;

                    if (k > bestsize) {
                        besti = i-k+1;
                        bestj = index-k+1;
                        bestsize = k;
                    }
                }
                index_to_len = new_index_to_len;
            }

            return new Match() { old_index=besti, new_index=bestj, length=bestsize };

        }

        public ArrayList<Match> get_all_blocks() {
            
            int len_old = old_message.char_count();
            int len_new = new_message.char_count();
            
            GLib.Queue<MessageSlice> queue = new GLib.Queue<MessageSlice>();
            queue.push_tail(new MessageSlice() { old_lo=0, old_hi=len_old, new_lo=0, new_hi=len_new });

            ArrayList<Match> matching_blocks = new ArrayList<Match>();

            while (!queue.is_empty()){

                MessageSlice message_slice = queue.pop_head();

                Match match = find_longest_match(message_slice);
                
                if (match.length > 0) {
                    matching_blocks.add(match);

                    if (message_slice.old_lo < match.old_index && message_slice.new_lo < match.new_index) {
                        queue.push_tail(new MessageSlice() { old_lo=message_slice.old_lo, old_hi=match.old_index, new_lo=message_slice.new_lo, new_hi=match.new_index });
                    }

                    if (match.old_index + match.length < message_slice.old_hi && match.new_index + match.length < message_slice.new_hi) {
                        queue.push_tail(new MessageSlice() { old_lo=match.old_index + match.length, old_hi=message_slice.old_hi, new_lo=match.new_index + match.length , new_hi=message_slice.new_hi });
                    }
                }

            }
            
            return matching_blocks;
        }

    }
}