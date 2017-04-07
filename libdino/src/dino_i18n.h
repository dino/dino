#ifndef __DINO_I18N_H__
#define __DINO_I18N_H__

#include<libintl.h>

#define dino_gettext(String) ((char *) dgettext (GETTEXT_PACKAGE, String))

#endif