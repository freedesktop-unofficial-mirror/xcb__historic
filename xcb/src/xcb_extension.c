/*
 * Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <assert.h>
#include <string.h>

#include "xcb.h"
#include "xcbint.h"

typedef struct XCBExtensionRecord {
    char *name;
    XCBQueryExtensionRep *info;
} XCBExtensionRecord;

static int match_extension_string(const void *name, const void *data)
{
    return (((XCBExtensionRecord *) data)->name == name);
}

/* Do not free the returned XCBQueryExtensionRep - on return, it's aliased
 * from the cache. */
const XCBQueryExtensionRep *XCBQueryExtensionCached(XCBConnection *c, const char *name, XCBGenericEvent **e)
{
    XCBExtensionRecord *data = 0;
    if(e)
        *e = 0;
    pthread_mutex_lock(&c->locked);

    data = (XCBExtensionRecord *) XCBListRemove(c->extension_cache, match_extension_string, name);

    if(!data)
    {
	/* cache miss: query the server */
	pthread_mutex_unlock(&c->locked);
	data = (XCBExtensionRecord *) malloc((1) * sizeof(XCBExtensionRecord));
	assert(data);
	data->name = (char *) name;
	data->info = XCBQueryExtensionReply(c, XCBQueryExtension(c, strlen(name), name), e);
	pthread_mutex_lock(&c->locked);
    }

    XCBListInsert(c->extension_cache, data);

    pthread_mutex_unlock(&c->locked);
    return data->info;
}
