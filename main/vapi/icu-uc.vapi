namespace ICU {

[CCode (cname = "UProperty", cprefix = "UCHAR_", has_type_id = false, cheader_filename = "unicode/uchar.h")]
public enum Property {
    EMOJI,
    EMOJI_PRESENTATION,
    EMOJI_MODIFIER,
    EMOJI_MODIFIER_BASE,
    BIDI_CLASS,
}

[CCode (cname = "UCharDirection", cprefix = "U_", has_type_id = false, cheader_filename = "unicode/uchar.h")]
public enum CharDirection {
    DIR_NON_SPACING_MARK,
}

[CCode (cname = "u_hasBinaryProperty", cheader_filename = "unicode/uchar.h")]
public bool has_binary_property(unichar c, Property p);

[CCode (cname = "u_getIntPropertyValue", cheader_filename = "unicode/uchar.h")]
public int32 get_int_property_value(unichar c, Property p);

}
