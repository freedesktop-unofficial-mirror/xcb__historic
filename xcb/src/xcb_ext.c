/* Copyright (C) 2001-2004 Bart Massey and Jamey Sharp.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * Except as contained in this notice, the names of the authors or their
 * institutions shall not be used in advertising or otherwise to promote the
 * sale, use or other dealings in this Software without prior written
 * authorization from the authors.
 */

/* A cache for QueryExtension results. */

#include <stdlib.h>
#include <string.h>

#include "xcb.h"
#include "xcbext.h"
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
const XCBQueryExtensionRep *XCBGetExtensionData(XCBConnection *c, XCBExtension *ext)
{
    XCBExtensionRecord *data;
    const char *name = ext->name;

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
        data->info = XCBQueryExtensionReply(c, XCBQueryExtension(c, strlen(name), name), 0);
        pthread_mutex_lock(&c->ext.lock);
    }

    _xcb_list_insert(c->ext.extensions, data);

    pthread_mutex_unlock(&c->ext.lock);
    return data->info;
}

void XCBPrefetchExtensionData(XCBConnection *c, XCBExtension *ext)
{
    /* XXX: implement me, I'm an optimization */
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
