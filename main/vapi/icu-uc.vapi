namespace Unicode {
  [CCode (cprefix = "UCHAR_", cheader_filename = "unicode/uchar.h")]
  enum Property {
    EMOJI,
    EMOJI_PRESENTATION,
    EMOJI_MODIFIER,
    EMOJI_MODIFIER_BASE,
  }

  [CCode (cname = "u_hasBinaryProperty", cheader_filename = "unicode/uchar.h")]
  bool has_binary_property(unichar c, Property p);
}
