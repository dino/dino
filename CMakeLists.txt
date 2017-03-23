cmake_minimum_required(VERSION 3.0)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Prepare Plugins
set(PLUGINS omemo;openpgp)
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
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")

string(REGEX REPLACE "^liblib" "lib" LIBDIR_NAME "lib${LIB_SUFFIX}")
set(SHARE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}/share")

set(APPLICATION_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/applications")
set(BIN_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/bin")
set(DATA_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/dino")
set(ICON_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/icons")
set(INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/include")
set(LIB_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/${LIBDIR_NAME}")
set(PLUGIN_INSTALL_DIR "${DATA_INSTALL_DIR}/plugins")
set(VAPI_INSTALL_DIR "${SHARE_INSTALL_PREFIX}/vala/vapi")
set(TARGET_INSTALL LIBRARY DESTINATION ${LIB_INSTALL_DIR} RUNTIME DESTINATION ${BIN_INSTALL_DIR} PUBLIC_HEADER DESTINATION ${INCLUDE_INSTALL_DIR} ARCHIVE DESTINATION ${LIB_INSTALL_DIR})
set(PLUGIN_INSTALL LIBRARY DESTINATION ${PLUGIN_INSTALL_DIR} RUNTIME DESTINATION ${PLUGIN_INSTALL_DIR})

include(CheckCCompilerFlag)

macro(AddCFlagIfSupported flag)
   CHECK_C_COMPILER_FLAG(${flag} COMPILER_SUPPORTS${flag})
   if(${COMPILER_SUPPORTS${flag}})
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${flag}")
   endif()
endmacro()

macro(AddValaCFlagIfSupported flag)
   CHECK_C_COMPILER_FLAG(${flag} COMPILER_SUPPORTS${flag})
   if(${COMPILER_SUPPORTS${flag}})
      set(VALA_CFLAGS "${VALA_CFLAGS} ${flag}")
   endif()
endmacro()

if("Ninja" STREQUAL ${CMAKE_GENERATOR})
   AddCFlagIfSupported(-fdiagnostics-color COMPILER_SUPPORTS_fdiagnistics-color)
endif()

AddValaCFlagIfSupported(-Wno-deprecated-declarations)
AddValaCFlagIfSupported(-Wno-incompatible-pointer-types)
AddValaCFlagIfSupported(-Wno-int-conversion)
AddValaCFlagIfSupported(-Wno-discarded-qualifiers)

if(NOT NO_DEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
    set(CMAKE_VALA_FLAGS "${CMAKE_VALA_FLAGS} -g")
endif(NOT NO_DEBUG)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

find_package(Vala 0.30 REQUIRED)
if(VALA_VERSION VERSION_EQUAL "0.36.0")
    # Due to a bug on 0.36.0, we need to disable FAST_VAPI
    set(DISABLE_FAST_VAPI yes)
endif()

include(${VALA_USE_FILE})
include(MultiFind)
include(GlibCompileResourcesSupport)

set(GTK3_GLOBAL_VERSION 3.22)
set(GLib_GLOBAL_VERSION 2.38)

set(CMAKE_VALA_FLAGS "${CMAKE_VALA_FLAGS} --thread --target-glib=${GLib_GLOBAL_VERSION}")

add_subdirectory(qlite)
add_subdirectory(xmpp-vala)
add_subdirectory(libdino)
add_subdirectory(main)
add_subdirectory(plugins)

# uninstall target
configure_file("${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in" "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake" IMMEDIATE @ONLY)
add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/cmake_uninstall.cmake COMMENT "Uninstall the project...")
