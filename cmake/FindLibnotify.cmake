include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Libnotify
    PKG_CONFIG_NAME libnotify
    LIB_NAMES notify
    INCLUDE_NAMES libnotify/notify.h
    DEPENDS GIO GDKPixbuf2
)

if(Libnotify_FOUND AND NOT Libnotify_VERSION)
    find_path(Libnotify_INCLUDE_DIR "libnotify/notify-features.h" HINTS ${Libnotify_INCLUDE_DIRS})

    if(Libnotify_INCLUDE_DIR)
        file(STRINGS "${Libnotify_INCLUDE_DIR}/libnotify/notify-features.h" Libnotify_MAJOR_VERSION REGEX "^#define NOTIFY_VERSION_MAJOR +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define NOTIFY_VERSION_MAJOR +\\(?([0-9]+)\\)?$" "\\1" Libnotify_MAJOR_VERSION "${Libnotify_MAJOR_VERSION}")
        file(STRINGS "${Libnotify_INCLUDE_DIR}/libnotify/notify-features.h" Libnotify_MINOR_VERSION REGEX "^#define NOTIFY_VERSION_MINOR +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define NOTIFY_VERSION_MINOR +\\(?([0-9]+)\\)?$" "\\1" Libnotify_MINOR_VERSION "${Libnotify_MINOR_VERSION}")
        file(STRINGS "${Libnotify_INCLUDE_DIR}/libnotify/notify-features.h" Libnotify_MICRO_VERSION REGEX "^#define NOTIFY_VERSION_MICRO +\\(?([0-9]+)\\)?$")
        string(REGEX REPLACE "^#define NOTIFY_VERSION_MICRO +\\(?([0-9]+)\\)?$" "\\1" Libnotify_MICRO_VERSION "${Libnotify_MICRO_VERSION}")
        set(Libnotify_VERSION "${Libnotify_MAJOR_VERSION}.${Libnotify_MINOR_VERSION}.${Libnotify_MICRO_VERSION}")
        unset(Libnotify_MAJOR_VERSION)
        unset(Libnotify_MINOR_VERSION)
        unset(Libnotify_MICRO_VERSION)
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libnotify
    FOUND_VAR Libnotify_FOUND
    REQUIRED_VARS Libnotify_LIBRARY
    VERSION_VAR Libnotify_VERSION
)