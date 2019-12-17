##
# Compile vala files to their c equivalents for further processing. 
#
# The "vala_precompile" function takes care of calling the valac executable on
# the given source to produce c files which can then be processed further using
# default cmake functions.
#
# The first parameter provided is a variable, which will be filled with a list
# of c files outputted by the vala compiler. This list can than be used in
# conjuction with functions like "add_executable" or others to create the
# neccessary compile rules with CMake.
#
# The following sections may be specified afterwards to provide certain options
# to the vala compiler:
#
# SOURCES
#   A list of .vala files to be compiled. Please take care to add every vala
#   file belonging to the currently compiled project or library as Vala will
#   otherwise not be able to resolve all dependencies.
#
# PACKAGES
#   A list of vala packages/libraries to be used during the compile cycle. The
#   package names are exactly the same, as they would be passed to the valac
#   "--pkg=" option.
#
# OPTIONS
#   A list of optional options to be passed to the valac executable. This can be
#   used to pass "--thread" for example to enable multi-threading support.
#
# DEFINITIONS
#   A list of symbols to be used for conditional compilation. They are the same
#   as they would be passed using the valac "--define=" option.
#
# CUSTOM_VAPIS
#   A list of custom vapi files to be included for compilation. This can be
#   useful to include freshly created vala libraries without having to install
#   them in the system.
#
# GENERATE_VAPI
#   Pass all the needed flags to the compiler to create a vapi for
#   the compiled library. The provided name will be used for this and a
#   <provided_name>.vapi file will be created.
#
# GENERATE_HEADER
#   Let the compiler generate a header file for the compiled code. There will
#   be a header file as well as an internal header file being generated called
#   <provided_name>.h and <provided_name>_internal.h
#
# The following call is a simple example to the vala_precompile macro showing
# an example to every of the optional sections:
#
#   find_package(Vala "0.12" REQUIRED)
#   include(${VALA_USE_FILE})
#
#   vala_precompile(VALA_C
#     SOURCES
#       source1.vala
#       source2.vala
#       source3.vala
#     PACKAGES
#       gtk+-2.0
#       gio-1.0
#       posix
#     DIRECTORY
#       gen
#     OPTIONS
#       --thread
#     CUSTOM_VAPIS
#       some_vapi.vapi
#     GENERATE_VAPI
#       myvapi
#     GENERATE_HEADER
#       myheader
#     )
#
# Most important is the variable VALA_C which will contain all the generated c
# file names after the call.
##

##
# Copyright 2009-2010 Jakob Westhoff. All rights reserved.
# Copyright 2010-2011 Daniel Pfeifer
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#    1. Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
# 
#    2. Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY JAKOB WESTHOFF ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL JAKOB WESTHOFF OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of Jakob Westhoff
##

include(CMakeParseArguments)

function(_vala_mkdir_for_file file)
  get_filename_component(dir "${file}" DIRECTORY)
  file(MAKE_DIRECTORY "${dir}")
endfunction()

function(vala_precompile output)
    cmake_parse_arguments(ARGS "FAST_VAPI" "DIRECTORY;GENERATE_HEADER;GENERATE_VAPI;EXPORTS_DIR"
        "SOURCES;PACKAGES;OPTIONS;DEFINITIONS;CUSTOM_VAPIS;CUSTOM_DEPS;GRESOURCES" ${ARGN})

    # Header and internal header is needed to generate internal vapi
    if (ARGS_GENERATE_VAPI AND NOT ARGS_GENERATE_HEADER)
        set(ARGS_GENERATE_HEADER ${ARGS_GENERATE_VAPI})
    endif(ARGS_GENERATE_VAPI AND NOT ARGS_GENERATE_HEADER)

    if("Ninja" STREQUAL ${CMAKE_GENERATOR} AND NOT DISABLE_FAST_VAPI AND NOT ARGS_GENERATE_HEADER)
        set(ARGS_FAST_VAPI true)
    endif()

    if(ARGS_DIRECTORY)
        get_filename_component(DIRECTORY ${ARGS_DIRECTORY} ABSOLUTE)
    else(ARGS_DIRECTORY)
        set(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    endif(ARGS_DIRECTORY)
    if(ARGS_EXPORTS_DIR)
        set(ARGS_EXPORTS_DIR ${CMAKE_BINARY_DIR}/${ARGS_EXPORTS_DIR})
    else(ARGS_EXPORTS_DIR)
        set(ARGS_EXPORTS_DIR ${CMAKE_BINARY_DIR}/exports)
    endif(ARGS_EXPORTS_DIR)
    file(MAKE_DIRECTORY "${ARGS_EXPORTS_DIR}")
    include_directories(${DIRECTORY} ${ARGS_EXPORTS_DIR})

    set(vala_pkg_opts "")
    foreach(pkg ${ARGS_PACKAGES})
        list(APPEND vala_pkg_opts "--pkg=${pkg}")
    endforeach(pkg ${ARGS_PACKAGES})

    set(vala_define_opts "")
    foreach(def ${ARGS_DEFINITIONS})
        list(APPEND vala_define_opts "--define=${def}")
    endforeach(def ${ARGS_DEFINITIONS})

    set(custom_vapi_arguments "")
    if(ARGS_CUSTOM_VAPIS)
        foreach(vapi ${ARGS_CUSTOM_VAPIS})
            if(${vapi} MATCHES ${CMAKE_SOURCE_DIR} OR ${vapi} MATCHES ${CMAKE_BINARY_DIR})
                list(APPEND custom_vapi_arguments ${vapi})
            else (${vapi} MATCHES ${CMAKE_SOURCE_DIR} OR ${vapi} MATCHES ${CMAKE_BINARY_DIR})
                list(APPEND custom_vapi_arguments ${CMAKE_CURRENT_SOURCE_DIR}/${vapi})
            endif(${vapi} MATCHES ${CMAKE_SOURCE_DIR} OR ${vapi} MATCHES ${CMAKE_BINARY_DIR})
        endforeach(vapi ${ARGS_CUSTOM_VAPIS})
    endif(ARGS_CUSTOM_VAPIS)

    set(gresources_args "")
    if(ARGS_GRESOURCES)
        set(gresources_args --gresources "${ARGS_GRESOURCES}")
    endif(ARGS_GRESOURCES)

    set(in_files "")
    set(fast_vapi_files "")
    set(out_files "")
    set(out_extra_files "")
    set(out_deps_files "")

    set(vapi_arguments "")
    if(ARGS_GENERATE_VAPI)
        list(APPEND out_extra_files "${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_VAPI}.vapi")
        list(APPEND out_extra_files "${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_VAPI}_internal.vapi")
        set(vapi_arguments "--vapi=${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_VAPI}.vapi" "--internal-vapi=${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_VAPI}_internal.vapi")

        if(ARGS_PACKAGES)
            string(REPLACE ";" "\\n" pkgs "${ARGS_PACKAGES};${ARGS_CUSTOM_DEPS}")
            add_custom_command(OUTPUT "${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_VAPI}.deps" COMMAND echo -e "\"${pkgs}\"" > "${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_VAPI}.deps" COMMENT "Generating ${ARGS_GENERATE_VAPI}.deps")
        endif(ARGS_PACKAGES)
    endif(ARGS_GENERATE_VAPI)

    set(header_arguments "")
    if(ARGS_GENERATE_HEADER)
        list(APPEND out_extra_files "${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_HEADER}.h")
        list(APPEND out_extra_files "${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_HEADER}_internal.h")
        list(APPEND header_arguments "--header=${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_HEADER}.h")
        list(APPEND header_arguments "--internal-header=${ARGS_EXPORTS_DIR}/${ARGS_GENERATE_HEADER}_internal.h")
    endif(ARGS_GENERATE_HEADER)

    string(REPLACE " " ";" VALAC_FLAGS ${CMAKE_VALA_FLAGS})
    if (VALA_VERSION VERSION_GREATER "0.38")
        set(VALAC_COLORS "--color=always")
    endif ()

    if(ARGS_FAST_VAPI)
        foreach(src ${ARGS_SOURCES} ${ARGS_UNPARSED_ARGUMENTS})
            set(in_file "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
            list(APPEND in_files "${in_file}")
            string(REPLACE ".vala" ".c" src ${src})
            string(REPLACE ".gs" ".c" src ${src})
            string(REPLACE ".c" ".vapi" fast_vapi ${src})
            set(fast_vapi_file "${DIRECTORY}/${fast_vapi}")
            list(APPEND fast_vapi_files "${fast_vapi_file}")
            list(APPEND out_files "${DIRECTORY}/${src}")

            _vala_mkdir_for_file("${fast_vapi_file}")

            add_custom_command(OUTPUT ${fast_vapi_file}
            COMMAND
                ${VALA_EXECUTABLE}
            ARGS
                ${VALAC_COLORS}
                --fast-vapi ${fast_vapi_file}
                ${vala_define_opts}
                ${ARGS_OPTIONS}
                ${VALAC_FLAGS}
                ${in_file}
            DEPENDS
                ${in_file}
            COMMENT
                "Generating fast VAPI ${fast_vapi}"
            )
        endforeach(src ${ARGS_SOURCES} ${ARGS_UNPARSED_ARGUMENTS})

        foreach(src ${ARGS_SOURCES} ${ARGS_UNPARSED_ARGUMENTS})
            set(in_file "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
            string(REPLACE ".vala" ".c" c_code ${src})
            string(REPLACE ".gs" ".c" c_code ${c_code})
            string(REPLACE ".c" ".vapi" fast_vapi ${c_code})
            set(my_fast_vapi_file "${DIRECTORY}/${fast_vapi}")
            set(c_code_file "${DIRECTORY}/${c_code}")
            set(fast_vapi_flags "")
            set(fast_vapi_stamp "")
            foreach(fast_vapi_file ${fast_vapi_files})
                if(NOT "${fast_vapi_file}" STREQUAL "${my_fast_vapi_file}")
                    list(APPEND fast_vapi_flags --use-fast-vapi "${fast_vapi_file}")
                    list(APPEND fast_vapi_stamp "${fast_vapi_file}")
                endif()
            endforeach(fast_vapi_file)

            _vala_mkdir_for_file("${fast_vapi_file}")
            get_filename_component(dir "${c_code_file}" DIRECTORY)

            add_custom_command(OUTPUT ${c_code_file}
            COMMAND
                ${VALA_EXECUTABLE}
            ARGS
                ${VALAC_COLORS}
                "-C"
                "-d" ${dir}
                ${vala_pkg_opts}
                ${vala_define_opts}
                ${gresources_args}
                ${ARGS_OPTIONS}
                ${VALAC_FLAGS}
                ${fast_vapi_flags}
                ${in_file}
                ${custom_vapi_arguments}
            DEPENDS
                ${fast_vapi_stamp}
                ${in_file}
                ${ARGS_CUSTOM_VAPIS}
                ${ARGS_GRESOURCES}
            COMMENT
                "Generating C source ${c_code}"
            )
        endforeach(src)

        if(NOT "${out_extra_files}" STREQUAL "")
            add_custom_command(OUTPUT ${out_extra_files}
            COMMAND
                ${VALA_EXECUTABLE}
            ARGS
                ${VALAC_COLORS}
                -C -q --disable-warnings
                ${header_arguments}
                ${vapi_arguments}
                "-b" ${CMAKE_CURRENT_SOURCE_DIR}
                "-d" ${DIRECTORY}
                ${vala_pkg_opts}
                ${vala_define_opts}
                ${gresources_args}
                ${ARGS_OPTIONS}
                ${VALAC_FLAGS}
                ${in_files}
                ${custom_vapi_arguments}
            DEPENDS
                ${in_files}
                ${ARGS_CUSTOM_VAPIS}
                ${ARGS_GRESOURCES}
            COMMENT
                "Generating VAPI and headers for target ${output}"
            )
        endif()
    else(ARGS_FAST_VAPI)
        foreach(src ${ARGS_SOURCES} ${ARGS_UNPARSED_ARGUMENTS})
            set(in_file "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
            list(APPEND in_files "${in_file}")
            string(REPLACE ".vala" ".c" src ${src})
            string(REPLACE ".gs" ".c" src ${src})
            list(APPEND out_files "${DIRECTORY}/${src}")

            _vala_mkdir_for_file("${fast_vapi_file}")
        endforeach(src ${ARGS_SOURCES} ${ARGS_UNPARSED_ARGUMENTS})

        add_custom_command(OUTPUT ${out_files} ${out_extra_files}
        COMMAND
            ${VALA_EXECUTABLE}
        ARGS
            ${VALAC_COLORS}
            -C
            ${header_arguments}
            ${vapi_arguments}
            "-b" ${CMAKE_CURRENT_SOURCE_DIR}
            "-d" ${DIRECTORY}
            ${vala_pkg_opts}
            ${vala_define_opts}
            ${gresources_args}
            ${ARGS_OPTIONS}
            ${VALAC_FLAGS}
            ${in_files}
            ${custom_vapi_arguments}
        DEPENDS
            ${in_files}
            ${ARGS_CUSTOM_VAPIS}
            ${ARGS_GRESOURCES}
        COMMENT
            "Generating C code for target ${output}"
        )
    endif(ARGS_FAST_VAPI)
    set(${output} ${out_files} PARENT_SCOPE)
endfunction(vala_precompile)
