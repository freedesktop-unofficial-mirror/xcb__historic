/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <stdio.h>
#include <errno.h>
#include <assert.h>

int _XDefaultError(Display *dpy, XErrorEvent *event);
int _XDefaultIOError(Display *dpy);

XErrorHandler _XErrorFunction;
XIOErrorHandler _XIOErrorFunction;

int _XDefaultError(Display *dpy, XErrorEvent *event)
{
#if 0 /* not needed yet */
    char buffer[BUFSIZ];
    char mesg[BUFSIZ];
    char number[32];
    char *mtype = "XlibMessage";
    register _XExtension *ext = (_XExtension *)NULL;
    _XExtension *bext = (_XExtension *)NULL;
    XGetErrorText(dpy, event->error_code, buffer, BUFSIZ);
    XGetErrorDatabaseText(dpy, mtype, "XError", "X Error", mesg, BUFSIZ);
    (void) fprintf(fp, "%s:  %s\n  ", mesg, buffer);
    XGetErrorDatabaseText(dpy, mtype, "MajorCode", "Request Major code %d", 
        mesg, BUFSIZ);
    (void) fprintf(fp, mesg, event->request_code);
    if (event->request_code < 128) {
        sprintf(number, "%d", event->request_code);
        XGetErrorDatabaseText(dpy, "XRequest", number, "", buffer, BUFSIZ);
    } else {
        for (ext = dpy->ext_procs;
             ext && (ext->codes.major_opcode != event->request_code);
             ext = ext->next)
          ;
        if (ext)
            strcpy(buffer, ext->name);
        else
            buffer[0] = '\0';
    }
    (void) fprintf(fp, " (%s)\n", buffer);
    if (event->request_code >= 128) {
        XGetErrorDatabaseText(dpy, mtype, "MinorCode", "Request Minor code %d",
                              mesg, BUFSIZ);
        fputs("  ", fp);
        (void) fprintf(fp, mesg, event->minor_code);
        if (ext) {
            sprintf(mesg, "%s.%d", ext->name, event->minor_code);
            XGetErrorDatabaseText(dpy, "XRequest", mesg, "", buffer, BUFSIZ);
            (void) fprintf(fp, " (%s)", buffer);
        }
        fputs("\n", fp);
    }
    if (event->error_code >= 128) {
        /* kludge, try to find the extension that caused it */
        buffer[0] = '\0';
        for (ext = dpy->ext_procs; ext; ext = ext->next) {
            if (ext->error_string) 
                (*ext->error_string)(dpy, event->error_code, &ext->codes,
                                     buffer, BUFSIZ);
            if (buffer[0]) {
                bext = ext;
                break;
            }
            if (ext->codes.first_error &&
                ext->codes.first_error < (int)event->error_code &&
                (!bext || ext->codes.first_error > bext->codes.first_error))
                bext = ext;
        }    
        if (bext)
            sprintf(buffer, "%s.%d", bext->name,
                    event->error_code - bext->codes.first_error);
        else
            strcpy(buffer, "Value");
        XGetErrorDatabaseText(dpy, mtype, buffer, "", mesg, BUFSIZ);
        if (mesg[0]) {
            fputs("  ", fp);
            (void) fprintf(fp, mesg, event->resourceid);
            fputs("\n", fp);
        }
        /* let extensions try to print the values */
        for (ext = dpy->ext_procs; ext; ext = ext->next) {
            if (ext->error_values)
                (*ext->error_values)(dpy, event, fp);
        }
    } else if ((event->error_code == BadWindow) ||
               (event->error_code == BadPixmap) ||
               (event->error_code == BadCursor) ||
               (event->error_code == BadFont) ||
               (event->error_code == BadDrawable) ||
               (event->error_code == BadColor) ||
               (event->error_code == BadGC) ||
               (event->error_code == BadIDChoice) ||
               (event->error_code == BadValue) ||
               (event->error_code == BadAtom)) {
        if (event->error_code == BadValue)
            XGetErrorDatabaseText(dpy, mtype, "Value", "Value 0x%x",
                                  mesg, BUFSIZ);
        else if (event->error_code == BadAtom)
            XGetErrorDatabaseText(dpy, mtype, "AtomID", "AtomID 0x%x",
                                  mesg, BUFSIZ);
        else
            XGetErrorDatabaseText(dpy, mtype, "ResourceID", "ResourceID 0x%x",
                                  mesg, BUFSIZ);
        fputs("  ", fp);
        (void) fprintf(fp, mesg, event->resourceid);
        fputs("\n", fp);
    }
    XGetErrorDatabaseText(dpy, mtype, "ErrorSerial", "Error Serial #%d", 
                          mesg, BUFSIZ);
    fputs("  ", fp);
    (void) fprintf(fp, mesg, event->serial);
    XGetErrorDatabaseText(dpy, mtype, "CurrentSerial", "Current Serial #%d",
                          mesg, BUFSIZ);
    fputs("\n  ", fp);
    (void) fprintf(fp, mesg, dpy->request);
    fputs("\n", fp);
#else
    fprintf(stderr, "Error of type %d occured.\n", event->error_code);
#endif
    if (event->error_code == BadImplementation) return 0;
    exit(1);
    /*NOTREACHED*/
}

/* _XDefaultIOError - Default fatal system error reporting routine.  Called 
 * when an X internal system error is encountered. */
int _XDefaultIOError(Display *dpy)
{
#if 0 /* not needed yet */
        if (ECHECK(EPIPE)) {
            (void) fprintf (stderr,
        "X connection to %s broken (explicit kill or server shutdown).\r\n",
                            DisplayString (dpy));
        } else {
#endif
            (void) fprintf (stderr, 
                        "XIO:  fatal IO error %d (%s) on X server \"%s\"\r\n",
#ifdef WIN32
                        WSAGetLastError(), strerror(WSAGetLastError()),
#else
                        errno, strerror (errno),
#endif
                        DisplayString (dpy));
            (void) fprintf (stderr, 
         "      after %lu requests (%lu known processed) with %d events remainin
g.\r\n",
                        NextRequest(dpy) - 1, LastKnownRequestProcessed(dpy),
                        QLength(dpy));

#if 0 /* not needed yet */
        }
#endif
        exit(1);
	/*NOTREACHED*/
}

static void *_XSetHandler(void **dst, void *src, void *def)
{
    void *oldhandler;

    _XLockMutex(_Xglobal_lock);

    oldhandler = *dst;
    if (!oldhandler)
	oldhandler = def;
    *dst = src ? src : def;

    _XUnlockMutex(_Xglobal_lock);

    return oldhandler;
}

/* XErrorHandler - This procedure sets the X non-fatal error handler
 * (_XErrorFunction) to be the specified routine.  If NULL is passed in
 * the original error handler is restored. */
XErrorHandler XSetErrorHandler(XErrorHandler handler)
{
    return (XErrorHandler) _XSetHandler((void **)&_XErrorFunction, handler, _XDefaultError);
}

/* XIOErrorHandler - This procedure sets the X fatal I/O error handler
 * (_XIOErrorFunction) to be the specified routine.  If NULL is passed in 
 * the original error handler is restored. */
XIOErrorHandler XSetIOErrorHandler(XIOErrorHandler handler)
{
    return (XIOErrorHandler) _XSetHandler((void **)&_XIOErrorFunction, handler, _XDefaultIOError);
}

/* _XError - upcall internal or user protocol error handler. */
int _XError(Display *dpy, register xError *rep)
{
    /* 
     * X_Error packet encountered!  We need to unpack the error before
     * giving it to the user.
     */
    XEvent event; /* make it a large event */
    register _XAsyncHandler *async, *next;
    int rtn_val;

    event.xerror.serial = _XSetLastRequestRead(dpy, (xGenericReply *)rep);

    for (async = dpy->async_handlers; async; async = next) {
        next = async->next;
        if ((*async->handler)(dpy, (xReply *)rep,
                              (char *)rep, SIZEOF(xError), async->data))
            return 0;
    }

    event.xerror.display = dpy;
    event.xerror.type = X_Error;
    event.xerror.resourceid = rep->resourceID;
    event.xerror.error_code = rep->errorCode;
    event.xerror.request_code = rep->majorCode;
    event.xerror.minor_code = rep->minorCode;
    if (dpy->error_vec && !(*dpy->error_vec[rep->errorCode])(dpy, &event.xerror, rep))
        return 0;
    assert(_XErrorFunction != NULL);

#ifdef XTHREADS
    if (dpy->lock)
	(*dpy->lock->user_lock_display)(dpy);
    UnlockDisplay(dpy);
#endif /* XTHREADS */
    rtn_val = (*_XErrorFunction)(dpy, (XErrorEvent *)&event); /* upcall */
#ifdef XTHREADS
    LockDisplay(dpy);
    if (dpy->lock)
	(*dpy->lock->user_unlock_display)(dpy);
#endif /* XTHREADS */
    return rtn_val;
}
