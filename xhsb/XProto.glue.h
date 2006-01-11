#include <X11/XCB/xcb.h>

CARD32 _internAtom(XCBConnection *c, BOOL onlyIfExists, CARD16 name_len, char *name);
CARD32 _ListFontsWithInfo(XCBConnection *c, CARD16 max_names, CARD16 pattern_len, char *pattern);
