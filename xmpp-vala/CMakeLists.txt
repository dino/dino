find_packages(ENGINE_PACKAGES REQUIRED
    GDKPixbuf2
    Gee
    GIO
    GLib
    GObject
    ICU
)

set(ENGINE_DEFINITIONS "")

find_package(GIO)
if(GIO_VERSION VERSION_GREATER "2.60")
    message(STATUS "ALPN support enabled")
    set(ENGINE_DEFINITIONS ALPN_SUPPORT)
else()
    message(STATUS "No ALPN support, needs GIO >= 2.60")
endif()
set(ENGINE_EXTRA_OPTIONS ${MAIN_EXTRA_OPTIONS} --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi)

vala_precompile(ENGINE_VALA_C
SOURCES
    "src/core/namespace_state.vala"
    "src/core/stanza_attribute.vala"
    "src/core/stanza_node.vala"
    "src/core/stanza_reader.vala"
    "src/core/stanza_writer.vala"
    "src/core/xmpp_log.vala"
    "src/core/xmpp_stream.vala"

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
    "src/module/tls.vala"
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
    "src/module/xep/0054_vcard/module.vala"
    "src/module/xep/0060_pubsub.vala"
    "src/module/xep/0065_socks5_bytestreams.vala"
    "src/module/xep/0066_out_of_band_data.vala"
    "src/module/xep/0077_in_band_registration.vala"
    "src/module/xep/0082_date_time_profiles.vala"
    "src/module/xep/0084_user_avatars.vala"
    "src/module/xep/0085_chat_state_notifications.vala"
    "src/module/xep/0115_entitiy_capabilities.vala"
    "src/module/xep/0166_jingle.vala"
    "src/module/xep/0184_message_delivery_receipts.vala"
    "src/module/xep/0191_blocking_command.vala"
    "src/module/xep/0198_stream_management.vala"
    "src/module/xep/0199_ping.vala"
    "src/module/xep/0203_delayed_delivery.vala"
    "src/module/xep/0234_jingle_file_transfer.vala"
    "src/module/xep/0260_jingle_socks5_bytestreams.vala"
    "src/module/xep/0261_jingle_in_band_bytestreams.vala"
    "src/module/xep/0280_message_carbons.vala"
    "src/module/xep/0301_in_band_real_time_text/rtt_stanza.vala"
    "src/module/xep/0301_in_band_real_time_text/module.vala"
    "src/module/xep/0308_last_message_correction.vala"
    "src/module/xep/0313_message_archive_management.vala"
    "src/module/xep/0333_chat_markers.vala"
    "src/module/xep/0334_message_processing_hints.vala"
    "src/module/xep/0359_unique_stable_stanza_ids.vala"
    "src/module/xep/0363_http_file_upload.vala"
    "src/module/xep/0368_srv_records_tls.vala"
    "src/module/xep/0380_explicit_encryption.vala"
    "src/module/xep/0391_jingle_encrypted_transports.vala"
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
DEFINITIONS
    ${ENGINE_DEFINITIONS}
OPTIONS
    ${ENGINE_EXTRA_OPTIONS}
)

add_custom_target(xmpp-vala-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.deps
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="xmpp-vala")
add_library(xmpp-vala SHARED ${ENGINE_VALA_C})
add_dependencies(xmpp-vala xmpp-vala-vapi)
target_link_libraries(xmpp-vala ${ENGINE_PACKAGES})
set_target_properties(xmpp-vala PROPERTIES VERSION 0.1 SOVERSION 0)

install(TARGETS xmpp-vala ${TARGET_INSTALL})
install(FILES ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi ${CMAKE_BINARY_DIR}/exports/xmpp-vala.deps DESTINATION ${VAPI_INSTALL_DIR})
install(FILES ${CMAKE_BINARY_DIR}/exports/xmpp-vala.h DESTINATION ${INCLUDE_INSTALL_DIR})

if(BUILD_TESTS)
    vala_precompile(ENGINE_TEST_VALA_C
    SOURCES
        "tests/common.vala"
        "tests/testcase.vala"

        "tests/jid.vala"
        "tests/stanza.vala"
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
endif(BUILD_TESTS)
