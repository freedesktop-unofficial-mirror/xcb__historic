#include "xclint.h"
#include <X11/Xatom.h>
#include <X11/Xutil.h>

/*
 * This function instructs the window manager to change this window from
 * NormalState to IconicState.
 */
Status XIconifyWindow(Display *dpy, Window w, int screen)
{
    XClientMessageEvent ev;
    Atom prop;

    prop = XInternAtom(dpy, "WM_CHANGE_STATE", False);
    if(prop == None)
	return False;

    ev.type = ClientMessage;
    ev.window = w;
    ev.message_type = prop;
    ev.format = 32;
    ev.data.l[0] = IconicState;
    return XSendEvent(dpy, RootWindow(dpy, screen), False,
			SubstructureRedirectMask|SubstructureNotifyMask,
			(XEvent *)&ev);
}
