#define TEST_GET_WINDOW_ATTRIBUTES
#define TEST_GET_GEOMETRY
#define TEST_QUERY_TREE
#undef TEST_THREADS
#define VERBOSE
#undef SUPERVERBOSE

#ifdef TEST_THREADS
#include <pthread.h>
#endif

#ifdef VERBOSE
#include <stdio.h>
#endif

#include <stdlib.h>

#include <client/xp_core.h>
#include "reply_formats.h"

void try_events(XCB_Connection *c);
void wait_events(XCB_Connection *c);

static XCB_Connection *c;
static Window window;

int main(int argc, char **argv)
{
    CARD32 mask = 0;
    CARD32 values[6];
#ifdef TEST_GET_GEOMETRY
    XCB_GetGeometry_cookie geom[3];
    XCB_GetGeometry_Rep *geomrep[3];
#endif
#ifdef TEST_QUERY_TREE
    XCB_QueryTree_cookie tree[3];
    XCB_QueryTree_Rep *treerep[3];
#endif
#ifdef TEST_GET_WINDOW_ATTRIBUTES
    XCB_GetWindowAttributes_cookie attr[1];
    XCB_GetWindowAttributes_Rep *attrrep[1];
#endif
#ifdef TEST_THREADS
    pthread_t event_thread;
#endif

    c = XCB_Connect_Basic();

#ifdef TEST_THREADS
# ifdef VERBOSE
    printf("main() thread ID: %ld\n", pthread_self());
# endif
    /* don't do this cast. */
    pthread_create(&event_thread, 0, (void *(*)(void *))wait_events, c);
#endif

#if 1
    window = XCB_Generate_ID(c);
#else
    window = 0; /* should be an invalid ID */
#endif

    mask |= CWBackPixel;
    values[0] = c->roots[0].data->whitePixel;

    mask |= CWBorderPixel;
    values[1] = c->roots[0].data->blackPixel;

    mask |= CWBackingStore;
    values[2] = Always;

    mask |= CWOverrideRedirect;
    values[3] = xFalse;

    mask |= CWEventMask;
    values[4] = ButtonReleaseMask | ExposureMask | StructureNotifyMask
        | EnterWindowMask | LeaveWindowMask;

    mask |= CWDontPropagate;
    values[5] = ButtonPressMask;

    XCB_CreateWindow(c, c->roots[0].depths[0].data->depth,
	window, c->roots[0].data->windowId,
        /* x */ 20, /* y */ 200, /* width */ 150, /* height */ 150,
        /* border_width */ 10, /* class */ InputOutput,
        /* visual */ c->roots[0].data->rootVisualID, mask, values);
    XCB_MapWindow(c, window);

    /* Send off a collection of requests */
#ifdef TEST_GET_WINDOW_ATTRIBUTES
    attr[0] = XCB_GetWindowAttributes(c, window);
#endif
#ifdef TEST_GET_GEOMETRY
    geom[0] = XCB_GetGeometry(c, c->roots[0].data->windowId);
    geom[1] = XCB_GetGeometry(c, window);
#endif
#ifdef TEST_QUERY_TREE
# ifdef SUPERVERBOSE /* this produces a lot of output :) */
    tree[0] = XCB_QueryTree(c, c->roots[0].data->windowId);
# endif
    tree[1] = XCB_QueryTree(c, window);
#endif

    /* Start reading replies and possibly events */
#ifdef TEST_GET_GEOMETRY
    geomrep[0] = XCB_GetGeometry_Reply(c, geom[0], 0);
    formatGetGeometryReply(c->roots[0].data->windowId, geomrep[0]);
    free(geomrep[0]);
#endif

#ifdef TEST_QUERY_TREE
# ifdef SUPERVERBOSE /* this produces a lot of output :) */
    treerep[0] = XCB_QueryTree_Reply(c, tree[0], 0);
    formatQueryTreeReply(c->roots[0].data->windowId, treerep[0]);
    free(treerep[0]);
# endif
#endif

#ifdef TEST_GET_GEOMETRY
    geomrep[1] = XCB_GetGeometry_Reply(c, geom[1], 0);
    formatGetGeometryReply(window, geomrep[1]);
    free(geomrep[1]);
#endif

    /* Mix in some more requests */
#ifdef TEST_QUERY_TREE
    treerep[1] = XCB_QueryTree_Reply(c, tree[1], 0);
    formatQueryTreeReply(window, treerep[1]);

    if(treerep[1] && treerep[1]->parent && treerep[1]->parent != c->roots[0].data->windowId)
    {
        tree[2] = XCB_QueryTree(c, treerep[1]->parent);

# ifdef TEST_GET_GEOMETRY
        geom[2] = XCB_GetGeometry(c, treerep[1]->parent);
        geomrep[2] = XCB_GetGeometry_Reply(c, geom[2], 0);
        formatGetGeometryReply(treerep[1]->parent, geomrep[2]);
        free(geomrep[2]);
# endif

        treerep[2] = XCB_QueryTree_Reply(c, tree[2], 0);
        formatQueryTreeReply(treerep[1]->parent, treerep[2]);
        free(treerep[2]);
    }

    free(treerep[1]);
#endif

    /* Get the last reply of the first batch */
#if 1 /* if 0, leaves a reply in the reply queue */
#ifdef TEST_GET_WINDOW_ATTRIBUTES
    attrrep[0] = XCB_GetWindowAttributes_Reply(c, attr[0], 0);
    formatGetWindowAttributesReply(window, attrrep[0]);
    free(attrrep[0]);
#endif
#endif

#ifdef VERBOSE
    if(!XCB_List_is_empty(&c->reply_data))
        printf("Unexpected additional replies waiting, dunno why...\n");
#endif

#ifdef TEST_THREADS
    pthread_join(event_thread, 0);
#else
    wait_events(c);
#endif

    exit(0);
    /*NOTREACHED*/
}

int wait_event(XCB_Connection *c)
{
    int ret = 1;
    XCB_Event *e = XCB_Wait_Event(c);

    if(!formatEvent(e))
        return 0;

    if(e->response_type == ButtonRelease)
        ret = 0; /* They clicked, therefore, we're done. */
    free(e);
    return ret;
}

void try_events(XCB_Connection *c)
{
    while(!XCB_EventQueueIsEmpty(c) && wait_event(c))
        /* empty statement */ ;
}

void wait_events(XCB_Connection *c)
{
#ifdef TEST_THREADS
# ifdef VERBOSE
    printf("wait_events() thread ID: %ld\n", pthread_self());
# endif
#endif
    while(wait_event(c))
        /* empty statement */ ;
}
