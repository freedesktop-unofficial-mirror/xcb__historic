#include "xclint.h"
// #include <X11/Xos.h>
#include <X11/Xresource.h>
#include <stdio.h>

#ifndef ERRORDB
#define ERRORDB "/usr/lib/X11/XErrorDB"
#endif

/*
 * descriptions of errors in Section 4 of Protocol doc (pp. 350-351); more
 * verbose descriptions are given in the error database
 */
static const char * const _XErrorList[] = {
    /* No error	*/		"no error",
    /* BadRequest */		"BadRequest",
    /* BadValue	*/		"BadValue",
    /* BadWindow */		"BadWindow",
    /* BadPixmap */		"BadPixmap",
    /* BadAtom */		"BadAtom",
    /* BadCursor */		"BadCursor",
    /* BadFont */		"BadFont",
    /* BadMatch	*/		"BadMatch",
    /* BadDrawable */		"BadDrawable",
    /* BadAccess */		"BadAccess",
    /* BadAlloc	*/		"BadAlloc",
    /* BadColor */  		"BadColor",
    /* BadGC */  		"BadGC",
    /* BadIDChoice */		"BadIDChoice",
    /* BadName */		"BadName",
    /* BadLength */		"BadLength",
    /* BadImplementation */	"BadImplementation",
};


int
XGetErrorText(dpy, code, buffer, nbytes)
    register int code;
    register Display *dpy;
    char *buffer;
    int nbytes;
{
    char buf[150];
    register _XExtension *ext;
    _XExtension *bext = (_XExtension *)NULL;

    if (nbytes == 0) return 0;
    if (code <= BadImplementation && code > 0) {
	sprintf(buf, "%d", code);
	(void) XGetErrorDatabaseText(dpy, "XProtoError", buf, _XErrorList[code],
				     buffer, nbytes);
    } else
	buffer[0] = '\0';
    /* call out to any extensions interested */
    for (ext = dpy->ext_procs; ext; ext = ext->next) {
 	if (ext->error_string)
 	    (*ext->error_string)(dpy, code, &ext->codes, buffer, nbytes);
	if (ext->codes.first_error &&
	    ext->codes.first_error < code &&
	    (!bext || ext->codes.first_error > bext->codes.first_error))
	    bext = ext;
    }    
    if (!buffer[0] && bext) {
	sprintf(buf, "%s.%d", bext->name, code - bext->codes.first_error);
	(void) XGetErrorDatabaseText(dpy, "XProtoError", buf, "", buffer, nbytes);
    }
    if (!buffer[0])
	sprintf(buffer, "%d", code);
    return 0;
}

int
#if NeedFunctionPrototypes
/*ARGSUSED*/
XGetErrorDatabaseText(
    Display *dpy,
    register _Xconst char *name,
    register _Xconst char *type,
    _Xconst char *defaultp,
    char *buffer,
    int nbytes)
#else
/*ARGSUSED*/
XGetErrorDatabaseText(dpy, name, type, defaultp, buffer, nbytes)
    Display *dpy;
    register char *name, *type;
    char *defaultp;
    char *buffer;
    int nbytes;
#endif
{

    static XrmDatabase db = NULL;
#if 0 /* not implemented yet */
    XrmString type_str;
#endif
    XrmValue result;
    char temp[BUFSIZ];
    char* tptr;
    unsigned long tlen;

    if (nbytes == 0) return 0;

#if 0 /* not implemented yet */
    if (!db) {
	/* the Xrm routines expect to be called with the global
	   mutex unlocked. */
	XrmDatabase temp_db;
	int do_destroy;

	XrmInitialize();
	temp_db = XrmGetFileDatabase(ERRORDB);

	_XLockMutex(_Xglobal_lock);
	if (!db) {
	    db = temp_db;
	    do_destroy = 0;
	} else
	    do_destroy = 1;	/* we didn't need to get it after all */
	_XUnlockMutex(_Xglobal_lock);

	if (do_destroy)
	    XrmDestroyDatabase(temp_db);
    }
#endif

    if (db)
    {
	tlen = strlen (name) + strlen (type) + 2;
	if (tlen <= BUFSIZE) tptr = temp;
	else tptr = Xmalloc (tlen);
	sprintf(tptr, "%s.%s", name, type);
#if 0 /* not implemented yet */
	XrmGetResource(db, tptr, "ErrorType.ErrorNumber", &type_str, &result);
#endif
	if (tptr != temp) Xfree (tptr);
    }
    else
	result.addr = (XPointer)NULL;
    if (!result.addr) {
	result.addr = (XPointer) defaultp;
	result.size = strlen(defaultp) + 1;
    }
    (void) strncpy (buffer, (char *) result.addr, nbytes);
    if (result.size > nbytes) buffer[nbytes-1] = '\0';
    return 0;
}
