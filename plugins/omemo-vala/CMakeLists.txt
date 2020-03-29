find_package(GCrypt REQUIRED)
find_packages(OMEMO_VALA_PACKAGES REQUIRED
    Gee
    GLib
    GObject
)

vala_precompile(OMEMO_VALA_VALA_C
SOURCES
    "src/context.vala"
    "src/simple_iks.vala"
    "src/simple_ss.vala"
    "src/simple_pks.vala"
    "src/simple_spks.vala"
    "src/store.vala"
    "src/util.vala"
CUSTOM_VAPIS
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/omemo-public.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/omemo-native.vapi
PACKAGES
    ${OMEMO_VALA_PACKAGES}
GENERATE_VAPI
    omemo-vala
GENERATE_HEADER
    omemo-vala
)

set(C_HEADERS_SRC "")
set(C_HEADERS_TARGET "")

add_subdirectory(libomemo-c EXCLUDE_FROM_ALL)
set_property(TARGET curve25519 PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET protobuf-c PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET omemo-c PROPERTY POSITION_INDEPENDENT_CODE ON)

if(NOT BUILD_LIBOMEMO_IN_TREE)
    find_package(Omemo REQUIRED)
else()
    set(OMEMO_C_HEADERS
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

    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/exports/omemo")

    foreach(f ${OMEMO_C_HEADERS})
        list(APPEND C_HEADERS_SRC "${CMAKE_CURRENT_SOURCE_DIR}/libomemo-c/src/${f}")
        list(APPEND C_HEADERS_TARGET "${CMAKE_BINARY_DIR}/exports/omemo/${f}")
        add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/omemo/${f}"
        COMMAND
            cp "${CMAKE_CURRENT_SOURCE_DIR}/libomemo-c/src/${f}" "${CMAKE_BINARY_DIR}/exports/omemo/${f}"
        DEPENDS
            "${CMAKE_CURRENT_SOURCE_DIR}/libomemo-c/src/${f}"
        COMMENT
            Copy header file omemo/${f}
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

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/exports/omemo.vapi
COMMAND
    cat "${CMAKE_CURRENT_SOURCE_DIR}/vapi/omemo-public.vapi" "${CMAKE_BINARY_DIR}/exports/omemo-vala.vapi" > "${CMAKE_BINARY_DIR}/exports/omemo.vapi"
DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/omemo-public.vapi
    ${CMAKE_BINARY_DIR}/exports/omemo-vala.vapi
)

add_custom_target(omemo-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/omemo.vapi
    ${CMAKE_BINARY_DIR}/exports/omemo-vala.h
    ${C_HEADERS_TARGET}
)

set(CFLAGS ${VALA_CFLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/libomemo-c/src -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_definitions(${CFLAGS})
add_library(omemo-vala ${OMEMO_VALA_VALA_C} ${CMAKE_CURRENT_SOURCE_DIR}/src/signal_helper.c)
add_dependencies(omemo-vala omemo-vapi)
target_link_libraries(omemo-vala ${OMEMO_VALA_PACKAGES} gcrypt omemo-c m)
set_property(TARGET omemo-vala PROPERTY POSITION_INDEPENDENT_CODE ON)

if(BUILD_TESTS)
    vala_precompile(OMEMO_TEST_VALA_C
    SOURCES
        "tests/common.vala"
        "tests/testcase.vala"

        "tests/curve25519.vala"
        "tests/hkdf.vala"
        "tests/session_builder.vala"
    CUSTOM_VAPIS
        ${CMAKE_BINARY_DIR}/exports/omemo-vala_internal.vapi
        ${CMAKE_CURRENT_SOURCE_DIR}/vapi/omemo-public.vapi
        ${CMAKE_CURRENT_SOURCE_DIR}/vapi/omemo-native.vapi
    PACKAGES
        ${OMEMO_VALA_PACKAGES}
    )

    set(CFLAGS ${VALA_CFLAGS} -I${CMAKE_CURRENT_BINARY_DIR}/omemo)
    add_executable(omemo-vala-test ${OMEMO_TEST_VALA_C})
    add_dependencies(omemo-vala-test omemo-vala)
    target_link_libraries(omemo-vala-test omemo-vala ${OMEMO_VALA_PACKAGES})
endif(BUILD_TESTS)
