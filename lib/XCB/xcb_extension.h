/*
 * This file generated automatically from xcb_extension.m4 by macros-xcb.m4 using m4.
 * Edit at your peril.
 */

#ifndef __XCB_EXTENSION_H
#define __XCB_EXTENSION_H
#include <xcb_trace.h>
#include <xcb.h>

/* Do not free the returned XCBQueryExtensionRep - on return, it's aliased
 * from the cache. */
const XCBQueryExtensionRep *XCBQueryExtensionCached(XCBConnection *c, const char *name, XCBGenericEvent **e);
#endif
