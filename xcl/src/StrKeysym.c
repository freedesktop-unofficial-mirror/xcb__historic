#include "xclint.h"
#include <X11/Xresource.h>
#include <X11/keysymdef.h>

/* don't want to drag in too much Xrm stuff yet: leave off for now. */
#define USE_XRM 0

#if USE_XRM
extern XrmQuark _XrmInternalStringToQuark();

#ifndef KEYSYMDB
#define KEYSYMDB "/usr/lib/X11/XKeysymDB"
#endif

static Bool initialized;
static XrmDatabase keysymdb;
static XrmQuark Qkeysym[2];
#endif

XrmDatabase _XInitKeysymDB()
{
#if USE_XRM
    if (!initialized)
    {
	char *dbname;

	XrmInitialize();
	/* use and name of this env var is not part of the standard */
	/* implementation-dependent feature */
	dbname = getenv("XKEYSYMDB");
	if (!dbname)
	    dbname = KEYSYMDB;
	keysymdb = XrmGetFileDatabase(dbname);
	if (keysymdb)
	    Qkeysym[0] = XrmStringToQuark("Keysym");
	initialized = True;
    }
    return keysymdb;
#else
    return 0;
#endif
}

KeySym XStringToKeysym(const char *s)
{
    KeySym val;

#if USE_XRM
    if (!initialized)
	_XInitKeysymDB();
    if (keysymdb)
    {
	XrmValue result;
	XrmRepresentation from_type;
	XrmQuark names[] = { XrmStringToQuark(s), NULLQUARK };

	XrmQGetResource(keysymdb, names, Qkeysym, &from_type, &result);
	if (result.addr && (result.size > 1))
	{
	    char *end;
	    val = strtoul((char *) result.addr, &end, 16);
	    if (end - (char *) result.addr != result.size - 1)
		return NoSymbol;
	    return val;
	}
    }
#endif

    if (*s == 'U') {
	char *end;
	val = strtoul(s + 1, &end, 16);
	if (!*end && val < 0x01000000)
	    return val | 0x01000000;
    }
    return NoSymbol;
}
