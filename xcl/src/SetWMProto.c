#include "xclint.h"
#include <X11/Xatom.h>

/* 
 * XSetWMProtocols sets the property 
 *	WM_PROTOCOLS 	type: ATOM	format: 32
 */

Status XSetWMProtocols (dpy, w, protocols, count)
    Display *dpy;
    Window w;
    Atom *protocols;
    int count;
{
    Atom prop;

    prop = XInternAtom (dpy, "WM_PROTOCOLS", False);
    if (prop == None) return False;

    XChangeProperty (dpy, w, prop, XA_ATOM, 32,
		     PropModeReplace, (unsigned char *) protocols, count);
    return True;
}
