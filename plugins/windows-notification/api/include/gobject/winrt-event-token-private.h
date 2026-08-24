#ifndef __WINRT_GLIB_EVENTTOKEN_PRIVATE_H__
#define __WINRT_GLIB_EVENTTOKEN_PRIVATE_H__

#include <glib.h>
#include "winrt-headers.h"

#include "winrt-event-token.h"

winrtEventToken* winrt_event_token_new_from_token(winrt::event_token* token);
winrt::event_token* winrt_event_token_get_internal(winrtEventToken* self);

#endif /* __WINRT_GLIB_EVENTTOKEN_PRIVATE_H__ */
