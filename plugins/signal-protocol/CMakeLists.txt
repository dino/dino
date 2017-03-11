add_subdirectory(libsignal-protocol-c)
set_property(TARGET curve25519 PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET protobuf-c PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET signal-protocol-c PROPERTY POSITION_INDEPENDENT_CODE ON)

find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
include(${VALA_USE_FILE})

set(SIGNAL_PROTOCOL_PACKAGES
    glib-2.0
    gee-0.8
    gobject-2.0
)

pkg_check_modules(SIGNAL_PROTOCOL REQUIRED ${SIGNAL_PROTOCOL_PACKAGES})

vala_precompile(SIGNAL_PROTOCOL_VALA_C
SOURCES
    "src/context.vala"
    "src/simple_iks.vala"
    "src/simple_ss.vala"
    "src/simple_pks.vala"
    "src/simple_spks.vala"
    "src/store.vala"
    "src/util.vala"
CUSTOM_VAPIS
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-public.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-native.vapi
PACKAGES
    ${SIGNAL_PROTOCOL_PACKAGES}
GENERATE_VAPI
    signal-protocol-vala
GENERATE_HEADER
    signal-protocol-vala
OPTIONS
    ${GLOBAL_DEBUG_FLAGS}
    --thread
)

set(CFLAGS ${VALA_CFLAGS} ${SIGNAL_PROTOCOL_CFLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_definitions(${CFLAGS})
add_library(signal-protocol-vala ${SIGNAL_PROTOCOL_VALA_C} ${CMAKE_CURRENT_SOURCE_DIR}/src/signal_helper.c)
add_dependencies(signal-protocol-vala signal-protocol-c)
target_link_libraries(signal-protocol-vala ${SIGNAL_PROTOCOL_LIBRARIES} ${OPENSSL_CRYPTO_LIBRARY} signal-protocol-c -lm)
set_property(TARGET signal-protocol-vala PROPERTY POSITION_INDEPENDENT_CODE ON)

set(SIGNAL_PROTOCOL_C_HEADERS
    signal_protocol.h
    signal_protocol_types.h
    curve.h
    hkdf.h
    ratchet.h
    protocol.h
    session_state.h
    session_record.h
    session_pre_key.h
    session_builder.h
    session_cipher.h
    key_helper.h
    sender_key.h
    sender_key_state.h
    sender_key_record.h
    group_session_builder.h
    group_cipher.h
    fingerprint.h
    device_consistency.h
)

set(C_HEADERS_SRC "")
set(C_HEADERS_TARGET "")

foreach(f ${SIGNAL_PROTOCOL_C_HEADERS})
    list(APPEND C_HEADERS_SRC "${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src/${f}")
    list(APPEND C_HEADERS_TARGET "${CMAKE_BINARY_DIR}/exports/${f}")
    add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/${f}"
    COMMAND
        cp "${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src/${f}" "${CMAKE_BINARY_DIR}/exports/${f}"
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src/${f}"
    COMMENT
        Copy header file ${f}
    )
endforeach(f)

list(APPEND C_HEADERS_SRC "${CMAKE_CURRENT_SOURCE_DIR}/src/signal_helper.h")
list(APPEND C_HEADERS_TARGET "${CMAKE_BINARY_DIR}/exports/signal_helper.h")

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/signal_helper.h"
COMMAND
    cp "${CMAKE_CURRENT_SOURCE_DIR}/src/signal_helper.h" "${CMAKE_BINARY_DIR}/exports/signal_helper.h"
DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/signal_helper.h"
COMMENT
    Copy header file signal_helper.h
)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/exports/signal-protocol.vapi
COMMAND
    cat "${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-public.vapi" "${CMAKE_BINARY_DIR}/exports/signal-protocol-vala.vapi" > "${CMAKE_BINARY_DIR}/exports/signal-protocol.vapi"
DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-public.vapi
    ${CMAKE_BINARY_DIR}/exports/signal-protocol-vala.vapi
)

add_custom_target(signal-protocol-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/signal-protocol.vapi
    ${CMAKE_BINARY_DIR}/exports/signal-protocol-vala.h
    ${C_HEADERS_TARGET}
)

if(BUILD_TESTING)
    vala_precompile(SIGNAL_TEST_VALA_C
    SOURCES
        "tests/common.vala"
        "tests/testcase.vala"

        "tests/curve25519.vala"
        "tests/hkdf.vala"
        "tests/session_builder.vala"
    CUSTOM_VAPIS
        ${CMAKE_BINARY_DIR}/exports/signal-protocol-vala-internal.vapi
        ${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-public.vapi
        ${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-native.vapi
    PACKAGES
        ${SIGNAL_PROTOCOL_PACKAGES}
    OPTIONS
        ${GLOBAL_DEBUG_FLAGS}
        --thread
    )

    set(CFLAGS ${VALA_CFLAGS} ${SIGNAL_PROTOCOL_CFLAGS} -I${CMAKE_CURRENT_BINARY_DIR}/signal-protocol)
    add_executable(signal-protocol-vala-test ${SIGNAL_TEST_VALA_C})
    add_dependencies(signal-protocol-vala-test signal-protocol-vala signal-protocol-vapi)
    target_link_libraries(signal-protocol-vala-test signal-protocol-vala)
endif(BUILD_TESTING)