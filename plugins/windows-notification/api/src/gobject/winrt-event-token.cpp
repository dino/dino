#include "winrt-event-token-private.h"

#define WINRT_EVENT_TOKEN_GET_PRIVATE(obj) \
  ((winrtEventTokenPrivate*) winrt_event_token_get_instance_private ((winrtEventToken*) (obj)))

typedef struct
{
  winrt::event_token* token;
} winrtEventTokenPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (winrtEventToken, winrt_event_token, G_TYPE_OBJECT)

static void winrt_event_token_finalize(GObject* self)
{
  winrtEventTokenPrivate* priv = WINRT_EVENT_TOKEN_GET_PRIVATE (self);

  delete priv->token;

  G_OBJECT_CLASS(winrt_event_token_parent_class)->dispose(self);
}

static void winrt_event_token_class_init (winrtEventTokenClass* klass)
{
  GObjectClass* gobject_class = G_OBJECT_CLASS(klass);

  gobject_class->finalize = winrt_event_token_finalize;
}

static void winrt_event_token_init (winrtEventToken *self)
{
}

/*< private >
 * winrt_event_token_get_internal:
 * @self: a #winrtEventToken
 *
 * Retrieves the `winrt::Windows::UI::Notifications::ToastNotification` object used by @self.
 *
 * Returns: (transfer none): a pointer to the internal toast notification instance
 */
winrt::event_token* winrt_event_token_get_internal(winrtEventToken *self)
{
  winrtEventTokenPrivate *priv = WINRT_EVENT_TOKEN_GET_PRIVATE(self);

  return priv->token;
}

/*< private >
 * winrt_event_token_new:
 * @doc: the document to be shown
 * 
 * Creates a new toast notification with a document already set.
 *
 * Returns: (transfer full): the newly created #winrtEventToken instance
 */
winrtEventToken* winrt_event_token_new_from_token(winrt::event_token* token)
{
  auto ret = static_cast<winrtEventToken*>(g_object_new (WINRT_TYPE_EVENT_TOKEN, NULL));
//   winrtEventTokenPrivate* priv = WINRT_EVENT_TOKEN_GET_PRIVATE(ret);
//   priv->token = new winrt::event_token(*token);
  return ret;
}

gboolean winrt_event_token_operator_bool(winrtEventToken* self)
{
  g_return_val_if_fail(WINRT_IS_EVENT_TOKEN(self), FALSE);

  return winrt_event_token_get_internal(self)->operator bool();
}

gint64 winrt_event_token_create_toast_notifier_get_value(winrtEventToken* self)
{
  g_return_val_if_fail (WINRT_IS_EVENT_TOKEN (self), 0);

  //return winrt_event_token_get_internal(self)->value;
  return 0;
}