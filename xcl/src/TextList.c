/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1991, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xlocale.h>
#include <X11/Xutil.h>

int XmbTextListToTextProperty(Display *dpy, char **list, int count, XICCEncodingStyle style, XTextProperty *text_prop)
{
#if 0 /* locales disabled */
    XLCd lcd = _XlcCurrentLC();
    
    if (lcd == NULL)
#endif
        return XLocaleNotSupported;

#if 0 /* locales disabled */
    return (*lcd->methods->mb_text_list_to_prop)(lcd, dpy, list, count, style, text_prop);
#endif
}
