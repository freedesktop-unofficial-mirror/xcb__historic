#include "xclint.h"
#include <X11/Xatom.h>
#include <X11/Xos.h>

static Status _XGetCStringProperty();

Status XFetchName (dpy, window, name)
    register Display *dpy;
    Window window;
    char **name;
{
    return _XGetCStringProperty(dpy, window, XA_WM_NAME, name);
}

Status XGetIconName (dpy, window, name)
    register Display *dpy;
    Window window;
    char **name;
{
    return _XGetCStringProperty(dpy, window, XA_WM_ICON_NAME, name);
}

static Status _XGetCStringProperty(register Display *dpy, Window w, ATOM property, char **name)
{
    XCBGetPropertyCookie c;
    XCBGetPropertyRep *p;

    c = XCBGetProperty(XCBConnectionOfDisplay(dpy), /* delete */ 0, XCLWINDOW(w), property, XCLATOM(XA_STRING), /* offset */ 0, /* length */ 1<<30);
    p = XCBGetPropertyReply(XCBConnectionOfDisplay(dpy), c, 0);

    if (!p || p->type.xid != XA_STRING || p->format != 8) {
	*name = NULL;
	free(p);
	return 0; /* failure */
    }

    /* allocate an extra byte to null-terminate the string. */
    *name = Xmalloc (p->value_len + 1);
    memcpy(*name, XCBGetPropertyvalue(p), p->value_len);
    (*name)[p->value_len] = '\0';
    free(p);
    return 1; /* success */
}
