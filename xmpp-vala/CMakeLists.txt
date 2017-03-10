find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
find_package(GPGME REQUIRED)
find_package(LIBUUID REQUIRED)
include(GlibCompileResourcesSupport)
include(${VALA_USE_FILE})

set(ENGINE_PACKAGES
    gee-0.8
    gio-2.0
    glib-2.0
    gtk+-3.0
)

pkg_check_modules(ENGINE REQUIRED ${ENGINE_PACKAGES})

vala_precompile(ENGINE_VALA_C
SOURCES
    "src/core/namespace_state.vala"
    "src/core/stanza_attribute.vala"
    "src/core/stanza_node.vala"
    "src/core/stanza_reader.vala"
    "src/core/stanza_writer.vala"
    "src/core/xmpp_stream.vala"

    "src/module/bind.vala"
    "src/module/iq/module.vala"
    "src/module/iq/stanza.vala"
    "src/module/message/module.vala"
    "src/module/message/stanza.vala"
    "src/module/presence/flag.vala"
    "src/module/presence/module.vala"
    "src/module/presence/stanza.vala"
    "src/module/roster/flag.vala"
    "src/module/roster/item.vala"
    "src/module/roster/module.vala"
    "src/module/sasl.vala"
    "src/module/stanza.vala"
    "src/module/stanza_error.vala"
    "src/module/stream_error.vala"
    "src/module/tls.vala"
    "src/module/util.vala"

    "src/module/xep/0027_pgp/flag.vala"
    "src/module/xep/0027_pgp/module.vala"
    "src/module/xep/0030_service_discovery/flag.vala"
    "src/module/xep/0030_service_discovery/info_result.vala"
    "src/module/xep/0030_service_discovery/items_result.vala"
    "src/module/xep/0030_service_discovery/module.vala"
    "src/module/xep/0045_muc/flag.vala"
    "src/module/xep/0045_muc/module.vala"
    "src/module/xep/0048_bookmarks/module.vala"
    "src/module/xep/0048_bookmarks/conference.vala"
    "src/module/xep/0049_private_xml_storage.vala"
    "src/module/xep/0054_vcard/module.vala"
    "src/module/xep/0060_pubsub.vala"
    "src/module/xep/0082_date_time_profiles.vala"
    "src/module/xep/0084_user_avatars.vala"
    "src/module/xep/0085_chat_state_notifications.vala"
    "src/module/xep/0115_entitiy_capabilities.vala"
    "src/module/xep/0199_ping.vala"
    "src/module/xep/0184_message_delivery_receipts.vala"
    "src/module/xep/0203_delayed_delivery.vala"
    "src/module/xep/0280_message_carbons.vala"
    "src/module/xep/0333_chat_markers.vala"
    "src/module/xep/pixbuf_storage.vala"
CUSTOM_VAPIS
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/uuid.vapi"
PACKAGES
    ${ENGINE_PACKAGES}
    gpgme
GENERATE_VAPI
    xmpp-vala
GENERATE_HEADER
    xmpp-vala
OPTIONS
    --target-glib=2.38
    -g
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

set(CFLAGS ${ENGINE_CFLAGS} ${GPGME_CFLAGS} ${LIBUUID_CFLAGS} -g ${VALA_CFLAGS})
add_definitions(${CFLAGS})
add_library(xmpp-vala SHARED ${ENGINE_VALA_C})
target_link_libraries(xmpp-vala ${ENGINE_LIBRARIES} ${GPGME_LIBRARIES} ${LIBUUID_LIBRARIES})

add_custom_target(xmpp-vala-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/xmpp-vala/xmpp-vala.vapi
)

