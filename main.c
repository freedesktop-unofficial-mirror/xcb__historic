#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include "xp_core.h"

#define InputOutput 1

void window_geom(XCB_Connection *c, XP_WINDOW wid);
XP_WINDOW window_tree(XCB_Connection *c, XP_WINDOW wid);

int main(int argc, char **argv)
{
    int fd;
    XCB_Connection *c;
    XP_CreateWindowValues values = { /* mask */ 0 };
    XP_WINDOW wid, parent;

    fd = XCB_Open(getenv("DISPLAY"));
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

    wid = XCB_Generate_ID(c);

    XP_CreateWindow(c, /* depth */ 16, wid, c->disp_info.roots[0].root,
        /* x */ 300, /* y */ 200, /* width */ 300, /* height */ 300,
        /* border_width */ 10, /* class */ InputOutput,
        /* visual */ c->disp_info.roots[0].root_visual, values);
    XP_MapWindow(c, wid);
    XP_Sync(c);
    window_geom(c, c->disp_info.roots[0].root);
#if 0 /* this produces a lot of output :) */
    window_tree(c, c->disp_info.roots[0].root);
#endif
    window_geom(c, wid);
    parent = window_tree(c, wid);
    if(parent)
    {
        window_geom(c, parent);
        window_tree(c, parent);
    }
    sleep(10);
    exit(0);
    /*NOTREACHED*/
}

void window_geom(XCB_Connection *c, XP_WINDOW wid)
{
    XCB_Geometry_cookie cookie;
    XP_Geometry_Reply *reply;

    cookie = XP_GetGeometry(c, wid);
    reply = XP_Geometry_Get_Reply(c, cookie);
    if(!reply)
    {
        fprintf(stderr, "Failed to get geometry for window 0x%x.\n", wid);
        return;
    }
    printf("Geometry for window 0x%x: %dx%d%+d%+d\n",
            wid, reply->width, reply->height, reply->x, reply->y);
    fflush(stdout);
    free(reply);
}

XP_WINDOW window_tree(XCB_Connection *c, XP_WINDOW wid)
{
    XCB_Tree_cookie cookie;
    XP_Tree_Reply *reply;
    XP_WINDOW ret;
    int i;

    cookie = XP_QueryTree(c, wid);
    reply = XP_Tree_Get_Reply(c, cookie);
    if(!reply)
    {
        fprintf(stderr, "Failed to get tree for window 0x%x.\n", wid);
        return 0;
    }
    printf("Window 0x%x has parent 0x%x, root 0x%x, and %d children%c\n",
           wid, reply->parent, reply->root, reply->children_length,
           reply->children_length ? ':' : '.');

    for(i = 0; i < reply->children_length; ++i)
        printf("    window 0x%x\n", reply->children[i]);

    fflush(stdout);
    ret = reply->parent;
    free(reply);
    return ret;
}
