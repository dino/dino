namespace Xmpp.Util {

 /**
  * Parse a number from a hexadecimal representation.
  *
  * Skips any whitespace at the start of the string, parses as many valid
  * characters as hexadecimal digits as possible (possibly zero) and returns
  * them as an integer value.
  *
  * ```
  * // 0xa
  * print("0x%lx\n", from_hex("A quick brown fox jumps over the lazy dog."));
  * ```
  */

public long from_hex(string numeral) {
    long result = 0;
    bool skipping_whitespace = true;
    foreach (uint8 byte in numeral.data) {
        char c = (char)byte;
        if (skipping_whitespace && c.isspace()) {
            continue;
        }
        skipping_whitespace = false;
        int digit;
        if ('0' <= c && c <= '9') {
            digit = c - '0';
        } else if ('A' <= c && c <= 'F') {
            digit = c - 'A' + 10;
        } else if ('a' <= c && c <= 'f') {
            digit = c - 'a' + 10;
        } else {
            break;
        }
        result = (result << 4) | digit;
    }
    return result;
}

}
