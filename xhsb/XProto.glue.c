#include "XProto.glue.h"

CARD32 _internAtom(XCBConnection *c, BOOL onlyIfExists, CARD16 name_len, char *name)
{
	XCBInternAtomCookie cookie = XCBInternAtom(c, onlyIfExists, name_len, name);
	return cookie.sequence;
}

CARD32 _ListFontsWithInfo(XCBConnection *c, CARD16 max_names, CARD16 pattern_len, char *pattern)
{
	XCBListFontsWithInfoCookie cookie = XCBListFontsWithInfo(c, max_names, pattern_len, pattern);
	return cookie.sequence;
}
