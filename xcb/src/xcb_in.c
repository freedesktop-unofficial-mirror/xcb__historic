/* Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * See the file COPYING for licensing information. */

/* Stuff that reads stuff from the server. */

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

#include "xcb.h"
#include "xcbint.h"

typedef struct XCBReplyData {
    pthread_cond_t cond;
    int pending;
    int error;
    unsigned int request;
    void *data;
} XCBReplyData;

static void free_reply_data(XCBReplyData *data)
{
    pthread_cond_destroy(&data->cond);
    free(data->data);
    free(data);
}

static int match_pending(const void *ignored, const void *data)
{
    return ((XCBReplyData *) data)->pending;
}

static int match_reply(const void *request, const void *data)
{
    return ((XCBReplyData *) data)->request == *(unsigned int *) request;
}

static void wake_up_next_reader(XCBConnection *c)
{
    XCBReplyData *cur = _xcb_list_find(c->in.replies, match_pending, 0);
    int pthreadret;
    if(cur)
        pthreadret = pthread_cond_signal(&cur->cond);
    else
        pthreadret = pthread_cond_signal(&c->in.event_cond);
    assert(pthreadret == 0);
}

/* Public interface */

void *XCBWaitReply(XCBConnection *c, unsigned int request, XCBGenericError **e)
{
    void *ret = 0;
    XCBReplyData *cur;
    if(e)
        *e = 0;

    pthread_mutex_lock(&c->iolock);

    /* If this request has not been written yet, write it. */
    if((signed int) (c->out.request_written - request) < 0)
        if(_xcb_out_flush(c) <= 0)
            goto done; /* error */

    /* Compare the sequence number as a full int. */
    cur = _xcb_list_find(c->in.replies, match_reply, &request);

    if(!cur || cur->pending)
        goto done; /* error */

    ++cur->pending;

    while(!cur->data)
        if(_xcb_conn_wait(c, /*should_write*/ 0, &cur->cond) <= 0)
        {
            /* Do not remove the reply record on I/O error. */
            --cur->pending;
            goto done;
        }

    /* No need to update pending flag - about to delete cur anyway. */

    if(cur->error)
    {
        if(!e)
            _xcb_list_append(c->in.events, (XCBGenericEvent *) cur->data);
        else
            *e = (XCBGenericError *) cur->data;
    }
    else
        ret = cur->data;

    _xcb_list_remove(c->in.replies, match_reply, &request);
    free(cur);

done:
    wake_up_next_reader(c);
    pthread_mutex_unlock(&c->iolock);
    return ret;
}

XCBGenericEvent *XCBWaitEvent(XCBConnection *c)
{
    XCBGenericEvent *ret;

#if XCBTRACEEVENT
    fprintf(stderr, "Entering XCBWaitEvent\n");
#endif

    pthread_mutex_lock(&c->iolock);
    while(_xcb_list_length(c->in.events) == 0)
        if(_xcb_conn_wait(c, /*should_write*/ 0, &c->in.event_cond) <= 0)
            break;
    /* _xcb_list_remove_head returns 0 on empty list. */
    ret = (XCBGenericEvent *) _xcb_list_remove_head(c->in.events);

    wake_up_next_reader(c);
    pthread_mutex_unlock(&c->iolock);

#if XCBTRACEEVENT
    fprintf(stderr, "Leaving XCBWaitEvent, event type %d\n", ret ? ret->response_type : -1);
#endif

    return ret;
}

int XCBEventQueueLength(XCBConnection *c)
{
    int ret;
    pthread_mutex_lock(&c->iolock);
    ret = _xcb_in_events_length(c);
    pthread_mutex_unlock(&c->iolock);
    return ret;
}

XCBGenericEvent *XCBEventQueueRemove(XCBConnection *c, XCBEventPredicate cmp, const XCBGenericEvent *data)
{
    XCBGenericEvent *ret;
    pthread_mutex_lock(&c->iolock);
    ret = _xcb_list_remove(c->in.events, (int (*)(const void *, const void *)) cmp, (const void *) data);
    pthread_mutex_unlock(&c->iolock);
    return ret;
}

XCBGenericEvent *XCBEventQueueFind(XCBConnection *c, XCBEventPredicate cmp, const XCBGenericEvent *data)
{
    XCBGenericEvent *ret;
    pthread_mutex_lock(&c->iolock);
    ret = _xcb_list_find(c->in.events, (int (*)(const void *, const void *)) cmp, (const void *) data);
    pthread_mutex_unlock(&c->iolock);
    return ret;
}

void XCBEventQueueClear(XCBConnection *c)
{
    pthread_mutex_lock(&c->iolock);
    _xcb_list_clear(c->in.events, free);
    pthread_mutex_unlock(&c->iolock);
}

/* Private interface */

int _xcb_in_init(_xcb_in *in)
{
    if(pthread_cond_init(&in->event_cond, 0))
        return 0;
    in->reading = 0;

    in->queue_len = 0;

    in->request_read = 0;

    in->replies = _xcb_list_new();
    in->events = _xcb_list_new();
    if(!in->replies || !in->events)
        return 0;

    in->unexpected_reply_handler = 0;
    in->unexpected_reply_data = 0;

    return 1;
}

void _xcb_in_destroy(_xcb_in *in)
{
    pthread_cond_destroy(&in->event_cond);
    _xcb_list_delete(in->replies, (XCBListFreeFunc) free_reply_data);
    _xcb_list_delete(in->events, free);
}

int _xcb_in_events_length(XCBConnection *c)
{
    /* FIXME: follow X meets Z architecture changes. */
    if(_xcb_in_read(c) <= 0)
        return -1;
    return _xcb_list_length(c->in.events);
}

int _xcb_in_expect_reply(XCBConnection *c, unsigned int request)
{
    XCBReplyData *data;
    data = malloc(sizeof(XCBReplyData));
    if(!data)
        return 0;

    pthread_cond_init(&data->cond, 0);
    data->pending = 0;
    data->error = 0;
    data->request = request;
    data->data = 0;

    _xcb_list_append(c->in.replies, data);
    return 1;
}

void _xcb_in_set_unexpected_reply_handler(XCBConnection *c, XCBUnexpectedReplyFunc handler, void *data)
{
    c->in.unexpected_reply_handler = handler;
    c->in.unexpected_reply_data = data;
}

int _xcb_in_read_packet(XCBConnection *c)
{
    XCBGenericRep genrep;
    int length = 32;
    XCBReplyData *rep = 0;
    unsigned char *buf;

    /* Wait for there to be enough data for us to read a whole packet */
    if(c->in.queue_len < length)
        return 0;

    /* Get the response type, length, and sequence number. */
    memcpy(&genrep, c->in.queue, sizeof(genrep));

    /* For reply packets, check that the entire packet is available. */
    if(genrep.response_type == 1)
        length += genrep.length * 4;

    buf = malloc(length);
    if(!buf)
        return 0;
    if(_xcb_in_read_block(c, buf, length) <= 0)
        return 0;

    /* Compute 32-bit sequence number of this packet. */
    /* XXX: do "sequence lost" check here */
    if((genrep.response_type & 0x7f) != KeymapNotify)
    {
        int lastread = c->in.request_read;
        c->in.request_read = (lastread & 0xffff0000) | genrep.sequence;
        if(c->in.request_read < lastread)
            c->in.request_read += 0x10000;
    }

    if(!(buf[0] & ~1)) /* reply or error packet */
        rep = (XCBReplyData *) _xcb_list_find(c->in.replies, match_reply, &c->in.request_read);

    if(buf[0] == 1 && !rep) /* I see no reply record here, but I need one. */
    {
        if(!c->in.unexpected_reply_handler ||
                !c->in.unexpected_reply_handler(c->in.unexpected_reply_data, (XCBGenericRep *) buf))
            fprintf(stderr, "No reply record found for reply %d.\n", c->in.request_read);
        free(buf);
        return 1; /* keep trying to read more packets */
    }

    if(rep) /* reply or error with a reply record. */
    {
        assert(rep->data == 0);
        rep->error = (buf[0] == 0);
        rep->data = buf;
        pthread_cond_signal(&rep->cond);
    }
    else /* event or error without a reply record */
    {
        _xcb_list_append(c->in.events, (XCBGenericEvent *) buf);
        pthread_cond_signal(&c->in.event_cond);
    }

    return 1; /* I have something for you... */
}

int _xcb_in_read(XCBConnection *c)
{
    int n = _xcb_readn(c->fd, c->in.queue, sizeof(c->in.queue), &c->in.queue_len);
    if(n < 0 && errno == EAGAIN)
        n = 1;
    while(_xcb_in_read_packet(c) > 0)
        /* empty */;
    return n;
}

int _xcb_in_read_block(XCBConnection *c, void *buf, int len)
{
    int done = c->in.queue_len;
    if(len < done)
        done = len;

    memcpy(buf, c->in.queue, done);
    c->in.queue_len -= done;
    memmove(c->in.queue, c->in.queue + done, c->in.queue_len);

    if(len > done)
    {
        int ret = _xcb_read_block(c->fd, (char *) buf + done, len - done);
        if(ret <= 0)
            return ret;
    }

    return len;
}