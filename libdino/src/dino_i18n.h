#ifndef __DINO_I18N_H__
#define __DINO_I18N_H__

#include<libintl.h>

#define dino_gettext(MsgId) ((char *) dgettext (GETTEXT_PACKAGE, MsgId))
#define dino_ngettext(MsgId, MsgIdPlural, Int) ((char *) dngettext (GETTEXT_PACKAGE, MsgId, MsgIdPlural, Int))

#endif