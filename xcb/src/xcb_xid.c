/* Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * See the file COPYING for licensing information. */

/* XID allocators. */

#include "xcb.h"
#include "xcbint.h"

/* Public interface */

CARD32 XCBGenerateID(XCBConnection *c)
{
    CARD32 ret;
    pthread_mutex_lock(&c->xid.lock);
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
    c->xid.inc = c->setup->resource_id_mask & -(c->setup->resource_id_mask);
    return 1;
}

void _xcb_xid_destroy(XCBConnection *c)
{
    pthread_mutex_destroy(&c->xid.lock);
}
