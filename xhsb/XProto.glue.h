#include <X11/XCB/xcb.h>

CARD32 _internAtom(XCBConnection *c, BOOL onlyIfExists, CARD16 name_len, char *name);
