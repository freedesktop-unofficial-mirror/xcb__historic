#include "xclint.h"
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/Xos.h>

void XSetWMSizeHints(Display *dpy, Window w, XSizeHints *hints, Atom prop)
{
    hints->flags &= USPosition|USSize|PPosition|PSize|PMinSize|PMaxSize|
		   PResizeInc|PAspect|PBaseSize|PWinGravity;
    XCBChangeProperty(XCBConnectionOfDisplay(dpy), PropModeReplace, XCLWINDOW(w), XCLATOM(prop), XCLATOM(XA_WM_SIZE_HINTS), 32, sizeof(*hints) >> 2, hints);
}

void XSetWMNormalHints(Display *dpy, Window w, XSizeHints *hints)
{
    XSetWMSizeHints(dpy, w, hints, XA_WM_NORMAL_HINTS);
}
