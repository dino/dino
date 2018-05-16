cmake_minimum_required(VERSION 3.0)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Prepare Plugins
set(PLUGINS omemo;openpgp;http-files)
if(DISABLED_PLUGINS)
    list(REMOVE_ITEM PLUGINS ${DISABLED_PLUGINS})
endif(DISABLED_PLUGINS)
if(ENABLED_PLUGINS)
    list(APPEND PLUGINS ${ENABLED_PLUGINS})
endif(ENABLED_PLUGINS)
list(REMOVE_DUPLICATES PLUGINS)

foreach(plugin ${PLUGINS})
    message(STATUS "Building plugin: ${plugin}")
    set(PLUGIN_ENABLED_${plugin} "yes")
endforeach(plugin)

# Prepare instal paths
macro(set_path what val desc)
    if(NOT ${what})
        unset(${what} CACHE)
        set(${what} ${val})
    endif()
    message(STATUS "${desc}: ${${what}}")
endmacro(set_path)

string(REGEX REPLACE "^liblib" "lib" LIBDIR_NAME "lib${LIB_SUFFIX}")
message(STATUS "Installation directory for architecture-independent files: ${CMAKE_INSTALL_PREFIX}")
set_path(EXEC_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}" "Installation directory for architecture-dependent files")
set_path(SHARE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/share" "Installation directory for read-only architecture-independent data")

set_path(BIN_INSTALL_DIR "${EXEC_INSTALL_PREFIX}/bin" "Installation directory for user executables")
set_path(DATA_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/dino" "Installation directory for dino-specific data")
set_path(APPDATA_FILE_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/metainfo" "Installation directory for .appdata.xml files")
set_path(DESKTOP_FILE_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/applications" "Installation directory for .desktop files")
set_path(SERVICE_FILE_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/dbus-1/services" "Installation directory for .service files")
set_path(ICON_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/icons" "Installation directory for icons")
set_path(INCLUDE_INSTALL_DIR "${EXEC_INSTALL_PREFIX}/include" "Installation directory for C header files")
set_path(LIB_INSTALL_DIR "${EXEC_INSTALL_PREFIX}/${LIBDIR_NAME}" "Installation directory for object code libraries")
set_path(LOCALE_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/locale" "Installation directory for locale files")
set_path(PLUGIN_INSTALL_DIR "${LIB_INSTALL_DIR}/dino/plugins" "Installation directory for dino plugin object code files")
set_path(VAPI_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/vala/vapi" "Installation directory for Vala API files")

set(TARGET_INSTALL LIBRARY DESTINATION ${LIB_INSTALL_DIR} RUNTIME DESTINATION ${BIN_INSTALL_DIR} PUBLIC_HEADER DESTINATION ${INCLUDE_INSTALL_DIR} ARCHIVE DESTINATION ${LIB_INSTALL_DIR})
set(PLUGIN_INSTALL LIBRARY DESTINATION ${PLUGIN_INSTALL_DIR} RUNTIME DESTINATION ${PLUGIN_INSTALL_DIR})

include(CheckCCompilerFlag)
include(CheckCSourceCompiles)

macro(AddCFlagIfSupported flag)
    string(REGEX REPLACE "[^a-z^A-Z^_^0-9]+" "_" flag_name ${flag})
    check_c_compiler_flag(${flag} COMPILER_SUPPORTS${flag_name})
    if(${COMPILER_SUPPORTS${flag_name}})
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${flag}")
    endif()
endmacro()

macro(AddValaCFlagIfSupported flag)
    string(REGEX REPLACE "[^a-z^A-Z^_^0-9]+" "_" flag_name ${flag})
    check_c_compiler_flag(${flag} COMPILER_SUPPORTS${flag_name})
    if(${COMPILER_SUPPORTS${flag_name}})
        set(VALA_CFLAGS "${VALA_CFLAGS} ${flag}")
    endif()
endmacro()

if("Ninja" STREQUAL ${CMAKE_GENERATOR})
   AddCFlagIfSupported(-fdiagnostics-color COMPILER_SUPPORTS_fdiagnistics-color)
endif()

AddCFlagIfSupported(-Wall)
AddCFlagIfSupported(-Werror=format-security)

AddValaCFlagIfSupported(-Wno-incompatible-pointer-types)
AddValaCFlagIfSupported(-Wno-pointer-sign)
AddValaCFlagIfSupported(-Wno-int-conversion)
AddValaCFlagIfSupported(-Wno-discarded-qualifiers)
AddValaCFlagIfSupported(-Wno-unused-but-set-variable)
AddValaCFlagIfSupported(-Wno-unused-variable)
AddValaCFlagIfSupported(-Wno-unused-function)
AddValaCFlagIfSupported(-Wno-unused-label)

try_compile(__WITHOUT_FILE_OFFSET_BITS_64 ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_SOURCE_DIR}/cmake/LargeFileOffsets.c COMPILE_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
if(NOT __WITHOUT_FILE_OFFSET_BITS_64)
    try_compile(__WITH_FILE_OFFSET_BITS_64 ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_SOURCE_DIR}/cmake/LargeFileOffsets.c COMPILE_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS} -D_FILE_OFFSET_BITS=64)

    if(__WITH_FILE_OFFSET_BITS_64)
        AddCFlagIfSupported(-D_FILE_OFFSET_BITS=64)
        AddValaCFlagIfSupported(-D_FILE_OFFSET_BITS=64)
        message(STATUS "Enabled large file support using _FILE_OFFSET_BITS=64")
    else(__WITH_FILE_OFFSET_BITS_64)
        message(STATUS "Large file support not available")
    endif(__WITH_FILE_OFFSET_BITS_64)
    unset(__WITH_FILE_OFFSET_BITS_64)
endif(NOT __WITHOUT_FILE_OFFSET_BITS_64)
unset(__WITHOUT_FILE_OFFSET_BITS_64)

if($ENV{USE_CCACHE})
    # Configure CCache if available
    find_program(CCACHE_FOUND ccache)
    if(CCACHE_FOUND)
        message(STATUS "Using ccache")
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
    else(CCACHE_FOUND)
        message(STATUS "USE_CCACHE was set but ccache was not found")
    endif(CCACHE_FOUND)
endif($ENV{USE_CCACHE})

if(NOT NO_DEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
    set(CMAKE_VALA_FLAGS "${CMAKE_VALA_FLAGS} -g")
endif(NOT NO_DEBUG)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

set(GTK3_GLOBAL_VERSION 3.22)
set(GLib_GLOBAL_VERSION 2.38)

if(NOT VALA_EXECUTABLE)
    unset(VALA_EXECUTABLE CACHE)
endif()

find_package(Vala 0.34 REQUIRED)
if(VALA_VERSION VERSION_GREATER "0.34.90" AND VALA_VERSION VERSION_LESS "0.36.1")
    # Due to a bug on 0.36.0 (and pre-releases), we need to disable FAST_VAPI
    set(DISABLE_FAST_VAPI yes)
endif()

include(${VALA_USE_FILE})
include(MultiFind)
include(GlibCompileResourcesSupport)

set(CMAKE_VALA_FLAGS "${CMAKE_VALA_FLAGS} --thread --target-glib=${GLib_GLOBAL_VERSION}")

add_subdirectory(qlite)
add_subdirectory(xmpp-vala)
add_subdirectory(libdino)
add_subdirectory(main)
add_subdirectory(plugins)

# uninstall target
configure_file("${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in" "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake" IMMEDIATE @ONLY)
add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/cmake_uninstall.cmake COMMENT "Uninstall the project...")
