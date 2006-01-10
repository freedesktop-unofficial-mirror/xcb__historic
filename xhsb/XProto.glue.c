#include "XProto.glue.h"

CARD32 _internAtom(XCBConnection *c, BOOL onlyIfExists, CARD16 name_len, char *name)
{
	XCBInternAtomCookie cookie = XCBInternAtom(c, onlyIfExists, name_len, name);
	return cookie.sequence;
}
