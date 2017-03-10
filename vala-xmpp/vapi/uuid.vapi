/* libuuid Vala Bindings
 * Copyright 2014 Evan Nemerson <evan@nemerson.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

[CCode (cheader_filename = "uuid.h", lower_case_cprefix = "uuid_")]
namespace UUID {
    [CCode (cname = "int", has_type_id = false)]
    public enum Variant {
        NCS,
        DCE,
        MICROSOFT,
        OTHER
    }

    [CCode (cname = "int", has_type_id = false)]
    public enum Type {
        DCE_TIME,
        DCE_RANDOM
    }

    public static void clear ([CCode (array_length = false)] uint8 uu[16]);
    public static void copy (uint8 dst[16], uint8 src[16]);

    public static void generate ([CCode (array_length = false)] uint8 @out[16]);
    public static void generate_random ([CCode (array_length = false)] uint8 @out[16]);
    public static void generate_time ([CCode (array_length = false)] uint8 @out[16]);
    public static void generate_time_safe ([CCode (array_length = false)] uint8 @out[16]);

    public static bool is_null ([CCode (array_length = false)] uint8 uu[16]);

    public static int parse (string in, [CCode (array_length = false)] uint8 uu[16]);

    public static void unparse ([CCode (array_length = false)] uint8 uu[16], [CCode (array_length = false)] char @out[37]);
    public static void unparse_lower ([CCode (array_length = false)] uint8 uu[16], [CCode (array_length = false)] char @out[37]);
    public static void unparse_upper ([CCode (array_length = false)] uint8 uu[16], [CCode (array_length = false)] char @out[37]);

//    public static time_t time ([CCode (array_length = false)] uint8 uu[16], out Posix.timeval ret_tv);
    public static UUID.Type type ([CCode (array_length = false)] uint8 uu[16]);
    public static UUID.Variant variant ([CCode (array_length = false)] uint8 uu[16]);
}
