find_package(GCrypt REQUIRED)
find_packages(SIGNAL_PROTOCOL_PACKAGES REQUIRED
    Gee
    GLib
    GObject
)

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
)

set(C_HEADERS_SRC "")
set(C_HEADERS_TARGET "")

if(NOT BUILD_LIBSIGNAL_IN_TREE)
    # libsignal-protocol-c has a history of breaking compatibility on the patch level
    # we'll have to check compatibility for every new release
    # distro maintainers may update this dependency after compatibility tests
    find_package(SignalProtocol 2.3.2 EXACT REQUIRED)
else()
    add_subdirectory(libsignal-protocol-c EXCLUDE_FROM_ALL)
    set_property(TARGET curve25519 PROPERTY POSITION_INDEPENDENT_CODE ON)
    set_property(TARGET protobuf-c PROPERTY POSITION_INDEPENDENT_CODE ON)
    set_property(TARGET signal-protocol-c PROPERTY POSITION_INDEPENDENT_CODE ON)

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

    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/exports/signal")

    foreach(f ${SIGNAL_PROTOCOL_C_HEADERS})
        list(APPEND C_HEADERS_SRC "${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src/${f}")
        list(APPEND C_HEADERS_TARGET "${CMAKE_BINARY_DIR}/exports/signal/${f}")
        add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/signal/${f}"
        COMMAND
            cp "${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src/${f}" "${CMAKE_BINARY_DIR}/exports/signal/${f}"
        DEPENDS
            "${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src/${f}"
        COMMENT
            Copy header file signal/${f}
        )
    endforeach(f)
endif()

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

set(CFLAGS ${VALA_CFLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/libsignal-protocol-c/src -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_definitions(${CFLAGS})
add_library(signal-protocol-vala ${SIGNAL_PROTOCOL_VALA_C} ${CMAKE_CURRENT_SOURCE_DIR}/src/signal_helper.c)
add_dependencies(signal-protocol-vala signal-protocol-vapi)
target_link_libraries(signal-protocol-vala ${SIGNAL_PROTOCOL_PACKAGES} gcrypt signal-protocol-c m)
set_property(TARGET signal-protocol-vala PROPERTY POSITION_INDEPENDENT_CODE ON)

if(BUILD_TESTS)
    vala_precompile(SIGNAL_TEST_VALA_C
    SOURCES
        "tests/common.vala"
        "tests/testcase.vala"

        "tests/curve25519.vala"
        "tests/hkdf.vala"
        "tests/session_builder.vala"
    CUSTOM_VAPIS
        ${CMAKE_BINARY_DIR}/exports/signal-protocol-vala_internal.vapi
        ${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-public.vapi
        ${CMAKE_CURRENT_SOURCE_DIR}/vapi/signal-protocol-native.vapi
    PACKAGES
        ${SIGNAL_PROTOCOL_PACKAGES}
    )

    set(CFLAGS ${VALA_CFLAGS} -I${CMAKE_CURRENT_BINARY_DIR}/signal-protocol)
    add_executable(signal-protocol-vala-test ${SIGNAL_TEST_VALA_C})
    add_dependencies(signal-protocol-vala-test signal-protocol-vala)
    target_link_libraries(signal-protocol-vala-test signal-protocol-vala ${SIGNAL_PROTOCOL_PACKAGES})
endif(BUILD_TESTS)
