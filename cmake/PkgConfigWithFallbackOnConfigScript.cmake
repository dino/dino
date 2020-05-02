include(CMakeParseArguments)

function(find_pkg_config_with_fallback_on_config_script name)
    cmake_parse_arguments(ARGS "" "PKG_CONFIG_NAME" "CONFIG_SCRIPT_NAME" ${ARGN})
    set(${name}_PKG_CONFIG_NAME ${ARGS_PKG_CONFIG_NAME} PARENT_SCOPE)
    find_package(PkgConfig)

    if(PKG_CONFIG_FOUND)
        pkg_search_module(${name}_PKG_CONFIG QUIET ${ARGS_PKG_CONFIG_NAME})
    endif(PKG_CONFIG_FOUND)

    if (${name}_PKG_CONFIG_FOUND)
        # Found via pkg-config, using it's result values
        set(${name}_FOUND ${${name}_PKG_CONFIG_FOUND})

        # Try to find real file name of libraries
        foreach(lib ${${name}_PKG_CONFIG_LIBRARIES})
            find_library(${name}_${lib}_LIBRARY ${lib} HINTS ${${name}_PKG_CONFIG_LIBRARY_DIRS})
            mark_as_advanced(${name}_${lib}_LIBRARY)
            if(NOT ${name}_${lib}_LIBRARY)
                find_library(${name}_${lib}_LIBRARY ${lib} HINTS "C:/msys64/mingw64/x86_64-w64-mingw32/lib")
                if(NOT ${name}_${lib}_LIBRARY)
                    unset(${name}_FOUND)
                endif(NOT ${name}_${lib}_LIBRARY)
            endif(NOT ${name}_${lib}_LIBRARY)
        endforeach(lib)
        if(${name}_FOUND)
            set(${name}_LIBRARIES "")
            foreach(lib ${${name}_PKG_CONFIG_LIBRARIES})
                list(APPEND ${name}_LIBRARIES ${${name}_${lib}_LIBRARY})
            endforeach(lib)
            list(REMOVE_DUPLICATES ${name}_LIBRARIES)
            set(${name}_LIBRARIES ${${name}_LIBRARIES} PARENT_SCOPE)
            list(GET ${name}_LIBRARIES "0" ${name}_LIBRARY)

            set(${name}_FOUND ${${name}_FOUND} PARENT_SCOPE)
            set(${name}_INCLUDE_DIRS ${${name}_PKG_CONFIG_INCLUDE_DIRS} PARENT_SCOPE)
            set(${name}_LIBRARIES ${${name}_PKG_CONFIG_LIBRARIES} PARENT_SCOPE)
            set(${name}_LIBRARY ${${name}_LIBRARY} PARENT_SCOPE)
            set(${name}_VERSION ${${name}_PKG_CONFIG_VERSION} PARENT_SCOPE)

            if(NOT TARGET ${ARGS_PKG_CONFIG_NAME})
                add_library(${ARGS_PKG_CONFIG_NAME} INTERFACE IMPORTED)
                set_property(TARGET ${ARGS_PKG_CONFIG_NAME} PROPERTY INTERFACE_COMPILE_OPTIONS "${${name}_PKG_CONFIG_CFLAGS_OTHER}")
                set_property(TARGET ${ARGS_PKG_CONFIG_NAME} PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${${name}_PKG_CONFIG_INCLUDE_DIRS}")
                set_property(TARGET ${ARGS_PKG_CONFIG_NAME} PROPERTY INTERFACE_LINK_LIBRARIES "${${name}_LIBRARIES}")
            endif(NOT TARGET ${ARGS_PKG_CONFIG_NAME})
        endif(${name}_FOUND)
    else(${name}_PKG_CONFIG_FOUND)
        # No success with pkg-config, try via custom a *-config script
        find_program(${name}_CONFIG_EXECUTABLE NAMES ${ARGS_CONFIG_SCRIPT_NAME}-config)
        mark_as_advanced(${name}_CONFIG_EXECUTABLE)
        find_program(${name}_SH_EXECUTABLE NAMES sh)
        mark_as_advanced(${name}_SH_EXECUTABLE)

        if(${name}_CONFIG_EXECUTABLE)
            macro(config_script_fail errcode)
                if(${errcode})
                    message(FATAL_ERROR "Error invoking ${ARGS_CONFIG_SCRIPT_NAME}-config: ${errcode}")
                endif(${errcode})
            endmacro(config_script_fail)
            file(TO_NATIVE_PATH "${${name}_CONFIG_EXECUTABLE}" ${name}_CONFIG_EXECUTABLE)
            file(TO_NATIVE_PATH "${${name}_SH_EXECUTABLE}" ${name}_SH_EXECUTABLE)

            execute_process(COMMAND "${${name}_SH_EXECUTABLE}" "${${name}_CONFIG_EXECUTABLE}" --version
                            OUTPUT_VARIABLE ${name}_VERSION
                            RESULT_VARIABLE ERRCODE
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            config_script_fail(${ERRCODE})

            execute_process(COMMAND "${${name}_SH_EXECUTABLE}" "${${name}_CONFIG_EXECUTABLE}" --api-version
                            OUTPUT_VARIABLE ${name}_API_VERSION
                            RESULT_VARIABLE ERRCODE
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            config_script_fail(${ERRCODE})

            execute_process(COMMAND "${${name}_SH_EXECUTABLE}" "${${name}_CONFIG_EXECUTABLE}" --cflags
                            OUTPUT_VARIABLE ${name}_CFLAGS
                            RESULT_VARIABLE ERRCODE
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            config_script_fail(${ERRCODE})

            execute_process(COMMAND "${${name}_SH_EXECUTABLE}" "${${name}_CONFIG_EXECUTABLE}" --libs
                            OUTPUT_VARIABLE ${name}_LDFLAGS
                            RESULT_VARIABLE ERRCODE
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            config_script_fail(${ERRCODE})

            string(TOLOWER ${name} "${name}_LOWER")
            string(REGEX REPLACE "^(.* |)-l([^ ]*${${name}_LOWER}[^ ]*)( .*|)$" "\\2" ${name}_LIBRARY_NAME "${${name}_LDFLAGS}")
            string(REGEX REPLACE "^(.* |)-L([^ ]*)( .*|)$" "\\2" ${name}_LIBRARY_DIRS "${${name}_LDFLAGS}")
            find_library(${name}_LIBRARY ${${name}_LIBRARY_NAME} HINTS ${${name}_LIBRARY_DIRS})
            mark_as_advanced(${name}_LIBRARY)
            set(${name}_LIBRARY ${${name}_LIBRARY} PARENT_SCOPE)
            set(${name}_VERSION ${${name}_VERSION} PARENT_SCOPE)
            unset(${name}_LIBRARY_NAME)
            unset(${name}_LIBRARY_DIRS)

            if(NOT TARGET ${name}_LOWER)
                add_library(${name}_LOWER INTERFACE IMPORTED)
                set_property(TARGET ${name}_LOWER PROPERTY INTERFACE_LINK_LIBRARIES "${${name}_LDFLAGS}")
                set_property(TARGET ${name}_LOWER PROPERTY INTERFACE_COMPILE_OPTIONS "${${name}_CFLAGS}")
            endif(NOT TARGET ${name}_LOWER)
        endif(${name}_CONFIG_EXECUTABLE)
    endif(${name}_PKG_CONFIG_FOUND)
endfunction()
