/* Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * See the file COPYING for licensing information. */

/* A cache for QueryExtension results. */

#include <stdlib.h>
#include <string.h>

#include "xcb.h"
#include "xcbint.h"

typedef struct XCBExtensionRecord {
    const char *name;
    XCBQueryExtensionRep *info;
} XCBExtensionRecord;

static void free_extension_record(XCBExtensionRecord *data)
{
    free(data->info);
    free(data);
}

static int match_extension_string(const void *name, const void *data)
{
    return (((XCBExtensionRecord *) data)->name == (const char *) name);
}

/* Public interface */

/* Do not free the returned XCBQueryExtensionRep - on return, it's aliased
 * from the cache. */
const XCBQueryExtensionRep *XCBQueryExtensionCached(XCBConnection *c, const char *name, XCBGenericError **e)
{
    XCBExtensionRecord *data;
    if(e)
        *e = 0;

    pthread_mutex_lock(&c->ext.lock);

    data = _xcb_list_remove(c->ext.extensions, match_extension_string, name);

    if(!data)
    {
        /* cache miss: query the server */
        pthread_mutex_unlock(&c->ext.lock);
        data = malloc(sizeof(XCBExtensionRecord));
        if(!data)
            return 0;
        data->name = name;
        data->info = XCBQueryExtensionReply(c, XCBQueryExtension(c, strlen(name), name), e);
        pthread_mutex_lock(&c->ext.lock);
    }

    _xcb_list_insert(c->ext.extensions, data);

    pthread_mutex_unlock(&c->ext.lock);
    return data->info;
}

/* Private interface */

int _xcb_ext_init(XCBConnection *c)
{
    if(pthread_mutex_init(&c->ext.lock, 0))
        return 0;

    c->ext.extensions = _xcb_list_new();
    if(!c->ext.extensions)
        return 0;

    return 1;
}

void _xcb_ext_destroy(XCBConnection *c)
{
    pthread_mutex_destroy(&c->ext.lock);
    _xcb_list_delete(c->ext.extensions, (XCBListFreeFunc) free_extension_record);
}
