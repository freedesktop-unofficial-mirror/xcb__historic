#undef TEST_GET_WINDOW_ATTRIBUTES
#define TEST_GET_GEOMETRY
#undef TEST_QUERY_TREE
#define TEST_EVENTS
#define TEST_THREADS

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#ifdef TEST_THREADS
#include <pthread.h>
#endif

#include "xp_core.h"
#include "reply_formats.h"

#ifdef TEST_GET_WINDOW_ATTRIBUTES
int window_attrs(XCB_Connection *c, Window wid);
#endif
#ifdef TEST_GET_GEOMETRY
int window_geom(XCB_Connection *c, Window wid);
#endif
#ifdef TEST_QUERY_TREE
Window window_tree(XCB_Connection *c, Window wid);
#endif
#ifdef TEST_EVENTS
int wait_event(XCB_Connection *c);
#endif

static XCB_Connection *c;
static Window window;

int main(int argc, char **argv)
{
    int fd;
    int screen = 0;
    CARD32 mask = 0;
    XP_CreateWindowValue values[6];
#ifdef TEST_QUERY_TREE
    Window parent;
#endif

    fd = XCB_Open(getenv("DISPLAY"), &screen);
    if(fd == -1)
    {
        perror("XCB_Open");
        abort();
    }

    c = XCB_Connect(fd);
    if(!c)
    {
        perror("XCB_Connect");
        abort();
    }
    printf("Connected.\n");
    fflush(stdout);

#if 1
    window = XCB_Generate_ID(c);
#else
    window = 0; /* should be an invalid ID */
#endif

    values[0].backgroundPixel = c->roots[0].data->whitePixel;
    mask |= CWBackPixel;
    values[1].borderPixel = c->roots[0].data->blackPixel;
    mask |= CWBorderPixel;
    values[2].backingStore = Always;
    mask |= CWBackingStore;
    values[3].overrideRedirect = xFalse;
    mask |= CWOverrideRedirect;
    values[4].eventMask = ButtonPressMask | ButtonReleaseMask | ExposureMask |
        EnterWindowMask | LeaveWindowMask | StructureNotifyMask;
    mask |= CWEventMask;
#if 0 /* this doesn't work - why not? */
    values[5].doNotPropagateMask = ButtonPressMask;
    mask |= CWDontPropagate;
#endif

    XP_CreateWindow(c, /* depth */ 16, window, c->roots[0].data->windowId,
        /* x */ 20, /* y */ 200, /* width */ 150, /* height */ 150,
        /* border_width */ 10, /* class */ InputOutput,
        /* visual */ c->roots[0].data->rootVisualID, mask, values);
    XP_MapWindow(c, window);
    XP_Sync(c);
#ifdef TEST_EVENTS
    while(c->event_data_head) /* don't do this. */
        wait_event(c);
#endif

#ifdef TEST_GET_GEOMETRY
    window_geom(c, c->roots[0].data->windowId);
#ifdef TEST_EVENTS
    while(c->event_data_head) /* don't do this. */
        wait_event(c);
#endif
#endif
#if 0 /* this produces a lot of output :) */
    window_tree(c, c->roots[0].data->windowId);
#endif
#ifdef TEST_GET_GEOMETRY
    window_geom(c, window);
#ifdef TEST_EVENTS
    while(c->event_data_head) /* don't do this. */
        wait_event(c);
#endif
#endif
#ifdef TEST_QUERY_TREE
    parent = window_tree(c, window);
    if(parent && parent != c->roots[0].data->windowId)
    {
#ifdef TEST_GET_GEOMETRY
        window_geom(c, parent);
#endif
        window_tree(c, parent);
    }
#endif

#ifdef TEST_GET_WINDOW_ATTRIBUTES
    window_attrs(c, window);
#endif

#ifdef TEST_EVENTS
    while(wait_event(c))
        /* empty statement */;
#endif

    exit(0);
    /*NOTREACHED*/
}

#ifdef TEST_GET_WINDOW_ATTRIBUTES
int window_attrs(XCB_Connection *c, Window wid)
{
    XCB_GetWindowAttributes_cookie cookie;
    xGetWindowAttributesReply *reply;

    cookie = XP_GetWindowAttributes(c, wid);
    reply = XP_GetWindowAttributes_Get_Reply(c, cookie);
    if(!reply)
    {
        fprintf(stderr, "Failed to get attributes for window 0x%x.\n",
            (unsigned int) wid);
        return 0;
    }

    formatGetWindowAttributesReply(wid, reply);
    free(reply);
    return 1;
}
#endif

#ifdef TEST_GET_GEOMETRY
int window_geom(XCB_Connection *c, Window wid)
{
    XCB_GetGeometry_cookie cookie;
    xGetGeometryReply *reply;

    cookie = XP_GetGeometry(c, wid);
    reply = XP_GetGeometry_Get_Reply(c, cookie);
    if(!reply)
    {
        fprintf(stderr, "Failed to get geometry for window 0x%x.\n",
            (unsigned int) wid);
        return 0;
    }

    formatGetGeometryReply(wid, reply);
    free(reply);
    return 1;
}
#endif

#ifdef TEST_QUERY_TREE
Window window_tree(XCB_Connection *c, Window wid)
{
    XCB_QueryTree_cookie cookie;
    xQueryTreeReply *reply;
    Window ret;
    int i;

    cookie = XP_QueryTree(c, wid);
    reply = XP_QueryTree_Get_Reply(c, cookie);
    if(!reply)
    {
        fprintf(stderr, "Failed to get tree for window 0x%x.\n", (unsigned int) wid);
        return 0;
    }

    formatQueryTreeReply(wid, reply);
    ret = reply->parent;
    free(reply);
    return ret;
}
#endif

#ifdef TEST_EVENTS
int wait_event(XCB_Connection *c)
{
    int ret = 1;
    XCB_Event *e = XCB_Wait_Event(c);

    if(!e)
    {
        fprintf(stderr, "An error occured while waiting for event.\n");
        return 0;
    }

    formatEvent(e);

    if(e->type == ButtonRelease)
        ret = 0; /* They clicked, therefore, we're done. */
    free(e);
    return ret;
}
#endif
