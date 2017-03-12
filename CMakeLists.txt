list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake
)

include(CheckCCompilerFlag)
macro(AddCFlagIfSupported flag test)
   CHECK_C_COMPILER_FLAG(${flag} ${test})
   if(${${test}})
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${flag}")
   endif()
endmacro()

cmake_minimum_required(VERSION 3.0)

if("Ninja" STREQUAL ${CMAKE_GENERATOR})
   AddCFlagIfSupported(-fdiagnostics-color COMPILER_SUPPORTS_fdiagnistics-color)
endif()

set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set (GLOBAL_DEBUG_FLAGS -g)
set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${GLOBAL_DEBUG_FLAGS}")
set (VALA_CFLAGS -Wno-deprecated-declarations -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-discarded-qualifiers)

add_subdirectory(qlite)
add_subdirectory(xmpp-vala)
add_subdirectory(libdino)
add_subdirectory(main)
add_subdirectory(plugins)
