/*
 * Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <stdlib.h>

#include "xcb.h"
#include "xcbint.h"

int XCBEventQueueIsEmpty(struct XCBConnection *c)
{
    int ret;
    pthread_mutex_lock(&c->locked);
    ret = XCBListIsEmpty(c->event_data);
    pthread_mutex_unlock(&c->locked);
    return ret;
}

int XCBEventQueueLength(struct XCBConnection *c)
{
    int ret;
    pthread_mutex_lock(&c->locked);
    ret = XCBListLength(c->event_data);
    pthread_mutex_unlock(&c->locked);
    return ret;
}

XCBGenericEvent *XCBEventQueueRemove(struct XCBConnection *c, int (*cmp)(const XCBGenericEvent *, const XCBGenericEvent *), const XCBGenericEvent *data)
{
    XCBGenericEvent *ret;
    pthread_mutex_lock(&c->locked);
    ret = XCBListRemove(c->event_data, (int (*)(const void *, const void *)) cmp, (const void *) data);
    pthread_mutex_unlock(&c->locked);
    return ret;
}

XCBGenericEvent *XCBEventQueueFind(struct XCBConnection *c, int (*cmp)(const XCBGenericEvent *, const XCBGenericEvent *), const XCBGenericEvent *data)
{
    XCBGenericEvent *ret;
    pthread_mutex_lock(&c->locked);
    ret = XCBListFind(c->event_data, (int (*)(const void *, const void *)) cmp, (const void *) data);
    pthread_mutex_unlock(&c->locked);
    return ret;
}

void XCBEventQueueClear(struct XCBConnection *c)
{
    void *tmp;
    pthread_mutex_lock(&c->locked);
    while((tmp = XCBListRemoveHead(c->event_data)))
        free(tmp);
    pthread_mutex_unlock(&c->locked);
}
