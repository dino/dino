#ifndef __WINRT_GLIB_EVENTTOKEN_H__
#define __WINRT_GLIB_EVENTTOKEN_H__

#if !defined(WINRT_GLIB_H_INSIDE) && !defined(WINRT_GLIB_COMPILATION)
#error "Only <winrt-glib.h> can be included directly."
#endif

#include "winrt-glib-types.h"

G_BEGIN_DECLS

#define WINRT_TYPE_EVENT_TOKEN (winrt_event_token_get_type())

G_DECLARE_DERIVABLE_TYPE (winrtEventToken, winrt_event_token, WINRT, EVENT_TOKEN, GObject)

struct _winrtEventTokenClass
{
    /*< private >*/
  GObjectClass parent_class;
};

#ifdef __cplusplus
extern "C"
{
#endif

gint64 winrt_event_token_get_value(winrtEventToken* self);
gboolean winrt_event_token_operator_bool(winrtEventToken* self);

#ifdef __cplusplus
}
#endif

G_END_DECLS

#endif /* __WINRT_GLIB_EVENTTOKEN_H__ */
