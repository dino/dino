find_packages(ENGINE_PACKAGES REQUIRED
    GDKPixbuf2
    Gee
    GIO
    GLib
    GObject
    ICU
)

set(ENGINE_EXTRA_OPTIONS ${MAIN_EXTRA_OPTIONS} --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi)

set(ENGINE_DEFINITIONS)
if(VALA_VERSION VERSION_EQUAL "0.56.11")
    set(ENGINE_DEFINITIONS ${ENGINE_DEFINITIONS} VALA_0_56_11)
endif()

vala_precompile(ENGINE_VALA_C
SOURCES
    "src/core/direct_tls_xmpp_stream.vala"
    "src/core/io_xmpp_stream.vala"
    "src/core/module_flag.vala"
    "src/core/starttls_xmpp_stream.vala"
    "src/core/stream_connect.vala"
    "src/core/tls_xmpp_stream.vala"
    "src/core/xmpp_stream.vala"

    "src/core/namespace_state.vala"
    "src/core/stanza_attribute.vala"
    "src/core/stanza_node.vala"
    "src/core/stanza_reader.vala"
    "src/core/stanza_writer.vala"
    "src/core/xmpp_log.vala"

    "src/module/bind.vala"
    "src/module/bookmarks_provider.vala"
    "src/module/conference.vala"
    "src/module/iq/module.vala"
    "src/module/iq/stanza.vala"
    "src/module/jid.vala"
    "src/module/message/module.vala"
    "src/module/message/stanza.vala"
    "src/module/presence/flag.vala"
    "src/module/presence/module.vala"
    "src/module/presence/stanza.vala"
    "src/module/roster/flag.vala"
    "src/module/roster/item.vala"
    "src/module/roster/module.vala"
    "src/module/roster/versioning_module.vala"
    "src/module/sasl.vala"
    "src/module/session.vala"
    "src/module/stanza.vala"
    "src/module/stanza_error.vala"
    "src/module/stream_error.vala"
    "src/module/util.vala"

    "src/module/xep/0048_bookmarks.vala"
    "src/module/xep/0048_conference.vala"
    "src/module/xep/0402_bookmarks2.vala"
    "src/module/xep/0004_data_forms.vala"

    "src/module/xep/0030_service_discovery/flag.vala"
    "src/module/xep/0030_service_discovery/identity.vala"
    "src/module/xep/0030_service_discovery/info_result.vala"
    "src/module/xep/0030_service_discovery/item.vala"
    "src/module/xep/0030_service_discovery/items_result.vala"
    "src/module/xep/0030_service_discovery/module.vala"

    "src/module/xep/0045_muc/flag.vala"
    "src/module/xep/0045_muc/module.vala"
    "src/module/xep/0045_muc/status_code.vala"

    "src/module/xep/0047_in_band_bytestreams.vala"
    "src/module/xep/0049_private_xml_storage.vala"
    "src/module/xep/0059_result_set_management.vala"
    "src/module/xep/0054_vcard/module.vala"
    "src/module/xep/0060_pubsub.vala"
    "src/module/xep/0065_socks5_bytestreams.vala"
    "src/module/xep/0066_out_of_band_data.vala"
    "src/module/xep/0077_in_band_registration.vala"
    "src/module/xep/0082_date_time_profiles.vala"
    "src/module/xep/0084_user_avatars.vala"
    "src/module/xep/0085_chat_state_notifications.vala"
    "src/module/xep/0115_entity_capabilities.vala"

    "src/module/xep/0166_jingle/content.vala"
    "src/module/xep/0166_jingle/content_description.vala"
    "src/module/xep/0166_jingle/content_node.vala"
    "src/module/xep/0166_jingle/content_security.vala"
    "src/module/xep/0166_jingle/content_transport.vala"
    "src/module/xep/0166_jingle/component.vala"
    "src/module/xep/0166_jingle/jingle_flag.vala"
    "src/module/xep/0166_jingle/jingle_module.vala"
    "src/module/xep/0166_jingle/jingle_structs.vala"
    "src/module/xep/0166_jingle/reason_element.vala"
    "src/module/xep/0166_jingle/session.vala"
    "src/module/xep/0166_jingle/session_info.vala"

    "src/module/xep/0167_jingle_rtp/content_parameters.vala"
    "src/module/xep/0167_jingle_rtp/content_type.vala"
    "src/module/xep/0167_jingle_rtp/jingle_rtp_module.vala"
    "src/module/xep/0167_jingle_rtp/payload_type.vala"
    "src/module/xep/0167_jingle_rtp/session_info_type.vala"
    "src/module/xep/0167_jingle_rtp/stream.vala"

    "src/module/xep/0176_jingle_ice_udp/candidate.vala"
    "src/module/xep/0176_jingle_ice_udp/jingle_ice_udp_module.vala"
    "src/module/xep/0176_jingle_ice_udp/transport_parameters.vala"

    "src/module/xep/0177_jingle_raw_udp.vala"

    "src/module/xep/0384_omemo/omemo_encryptor.vala"
    "src/module/xep/0384_omemo/omemo_decryptor.vala"

    "src/module/xep/0392_consistent_color/consistent_color.vala"
    "src/module/xep/0392_consistent_color/hsluv.vala"

    "src/module/xep/0184_message_delivery_receipts.vala"
    "src/module/xep/0191_blocking_command.vala"
    "src/module/xep/0198_stream_management.vala"
    "src/module/xep/0199_ping.vala"
    "src/module/xep/0203_delayed_delivery.vala"
    "src/module/xep/0215_external_service_discovery.vala"
    "src/module/xep/0234_jingle_file_transfer.vala"
    "src/module/xep/0249_direct_muc_invitations.vala"
    "src/module/xep/0260_jingle_socks5_bytestreams.vala"
    "src/module/xep/0261_jingle_in_band_bytestreams.vala"
    "src/module/xep/0272_muji.vala"
    "src/module/xep/0280_message_carbons.vala"
    "src/module/xep/0297_stanza_forwarding.vala"
    "src/module/xep/0298_coin.vala"
    "src/module/xep/0308_last_message_correction.vala"
    "src/module/xep/0313_message_archive_management.vala"
    "src/module/xep/0313_2_message_archive_management.vala"
    "src/module/xep/0333_chat_markers.vala"
    "src/module/xep/0334_message_processing_hints.vala"
    "src/module/xep/0353_jingle_message_initiation.vala"
    "src/module/xep/0353_call_invite_message.vala"
    "src/module/xep/0359_unique_stable_stanza_ids.vala"
    "src/module/xep/0363_http_file_upload.vala"
    "src/module/xep/0380_explicit_encryption.vala"
    "src/module/xep/0391_jingle_encrypted_transports.vala"
    "src/module/xep/0410_muc_self_ping.vala"
    "src/module/xep/0421_occupant_ids.vala"
    "src/module/xep/0428_fallback_indication.vala"
    "src/module/xep/0444_reactions.vala"
    "src/module/xep/0461_replies.vala"
    "src/module/xep/pixbuf_storage.vala"

    "src/util.vala"
PACKAGES
    ${ENGINE_PACKAGES}
GENERATE_VAPI
    xmpp-vala
GENERATE_HEADER
    xmpp-vala
CUSTOM_VAPIS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/glib_fixes.vapi"
OPTIONS
    ${ENGINE_EXTRA_OPTIONS}
DEFINITIONS
    ${ENGINE_DEFINITIONS}
)

add_custom_target(xmpp-vala-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.deps
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="xmpp-vala")
add_library(xmpp-vala SHARED ${ENGINE_VALA_C})
add_dependencies(xmpp-vala xmpp-vala-vapi)
target_link_libraries(xmpp-vala ${ENGINE_PACKAGES} m)
set_target_properties(xmpp-vala PROPERTIES VERSION 0.1 SOVERSION 0)

install(TARGETS xmpp-vala ${TARGET_INSTALL})
install(FILES ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi ${CMAKE_BINARY_DIR}/exports/xmpp-vala.deps DESTINATION ${VAPI_INSTALL_DIR})
install(FILES ${CMAKE_BINARY_DIR}/exports/xmpp-vala.h DESTINATION ${INCLUDE_INSTALL_DIR})

if(BUILD_TESTING)
    vala_precompile(ENGINE_TEST_VALA_C
    SOURCES
        "tests/common.vala"
        "tests/testcase.vala"

        "tests/jid.vala"
        "tests/stanza.vala"
        "tests/color.vala"
        "tests/util.vala"
    CUSTOM_VAPIS
        ${CMAKE_BINARY_DIR}/exports/xmpp-vala_internal.vapi
    PACKAGES
        ${ENGINE_PACKAGES}
    OPTIONS
        ${ENGINE_EXTRA_OPTIONS}
    )

    add_definitions(${VALA_CFLAGS})
    add_executable(xmpp-vala-test ${ENGINE_TEST_VALA_C})
    target_link_libraries(xmpp-vala-test xmpp-vala ${SIGNAL_PROTOCOL_PACKAGES})
    add_test(NAME xmpp-vala COMMAND xmpp-vala-test)
endif(BUILD_TESTING)
