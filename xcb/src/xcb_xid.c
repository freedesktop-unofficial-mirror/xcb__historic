/* Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * See the file COPYING for licensing information. */

/* XID allocators. */

#include <stdlib.h>
#include "xcb.h"
#include "xcbext.h"
#include "xcbint.h"
#include "extensions/xc_misc.h"

/* Public interface */

CARD32 XCBGenerateID(XCBConnection *c)
{
    CARD32 ret;
    pthread_mutex_lock(&c->xid.lock);
    if(c->xid.last == c->xid.max)
    {
	    XCBXCMiscGetXIDRangeRep *range;
	    range = XCBXCMiscGetXIDRangeReply(c, XCBXCMiscGetXIDRange(c), 0);
	    c->xid.last = range->start_id;
	    c->xid.max = range->start_id + (range->count - 1) * c->xid.inc;
	    free(range);
    }
    ret = c->xid.last | c->xid.base;
    c->xid.last += c->xid.inc;
    pthread_mutex_unlock(&c->xid.lock);
    return ret;
}

/* Private interface */

int _xcb_xid_init(XCBConnection *c)
{
    if(pthread_mutex_init(&c->xid.lock, 0))
        return 0;
    c->xid.last = 0;
    c->xid.base = c->setup->resource_id_base;
    c->xid.max = c->setup->resource_id_mask;
    c->xid.inc = c->setup->resource_id_mask & -(c->setup->resource_id_mask);
    return 1;
}

void _xcb_xid_destroy(XCBConnection *c)
{
    pthread_mutex_destroy(&c->xid.lock);
}
