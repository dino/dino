#pragma once

#include <glib.h>

#ifdef __cplusplus
#define EXTERN    extern "C"
#define NOEXCEPT  noexcept
#else
#define EXTERN
#define NOEXCEPT
#endif

EXTERN gboolean EnsureAumiddedShortcutExists(const gchar* aumid) NOEXCEPT;

#undef EXTERN
#undef NOEXCEPT
