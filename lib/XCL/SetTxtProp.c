#include "xclint.h"
#include <X11/Xatom.h>
#include <X11/Xutil.h>

void XSetTextProperty(Display *dpy, Window w, XTextProperty *tp, Atom property)
{
    XChangeProperty(dpy, w, property, tp->encoding, tp->format, PropModeReplace, tp->value, tp->nitems);
}

void XSetWMName(Display *dpy, Window w, XTextProperty *tp)
{
    XSetTextProperty(dpy, w, tp, XA_WM_NAME);
}

void XSetWMIconName(Display *dpy, Window w, XTextProperty *tp)
{
    XSetTextProperty(dpy, w, tp, XA_WM_ICON_NAME);
}

void XSetWMClientMachine(Display *dpy, Window w, XTextProperty *tp)
{
    XSetTextProperty(dpy, w, tp, XA_WM_CLIENT_MACHINE);
}
