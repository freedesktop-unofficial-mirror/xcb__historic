/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <xcb.h>
#include "reply_formats.h"
#include <math.h>
#include <stdlib.h> /* for free(3) */
#include <unistd.h> /* for usleep(3) */
#include <stdio.h>
#include <assert.h>
#include <pthread.h>

#define LAG 0.3 /* lag angle for the follow line */

/* If I've done my math right, Linux maxes out at 100 fps on Intel (1000 fps
 * on Alpha) due to the granularity of the kernel timer. */
#define FRAME_RATE 10.0 /* frames per second */

#define PI 3.14159265

static XCB_Connection *c;
static GCONTEXT white, black;

#define WINS 8
static struct {
	DRAWABLE w;
	DRAWABLE p;
	CARD16 width;
	CARD16 height;
	float angv;
} windows[WINS];

void *run(void *param);
void *event_thread(void *param);

int main()
{
	pthread_t thr;
	int i;

	CARD32 mask = GCForeground | GCGraphicsExposures;
	CARD32 values[2];
	DRAWABLE root;

	c = XCB_Connect_Basic();

	root.window = c->roots[0].data->root;
	white = XCB_GCONTEXT_New(c);
	black = XCB_GCONTEXT_New(c);

	pthread_create(&thr, 0, event_thread, 0);

	values[1] = 0; /* no graphics exposures */

	values[0] = c->roots[0].data->white_pixel;
	XCB_CreateGC(c, white, root, mask, values);

	values[0] = c->roots[0].data->black_pixel;
	XCB_CreateGC(c, black, root, mask, values);

	for(i = 1; i < WINS; ++i)
		pthread_create(&thr, 0, run, (void*)i);
	run((void*)0);

	exit(0);
	/*NOTREACHED*/
}

void paint(int idx)
{
	XCB_CopyArea(c, windows[idx].p, windows[idx].w, white, 0, 0, 0, 0,
		windows[idx].width, windows[idx].height);
	XCB_Sync(c, 0);
}

void *run(void *param)
{
	int idx = (int)param;

	int xo, yo;
	double r, theta = 0;

	POINT line[2];

	windows[idx].w.window = XCB_WINDOW_New(c);
	windows[idx].p.pixmap = XCB_PIXMAP_New(c);
	windows[idx].width = 300;
	line[0].x = xo = windows[idx].width / 2;
	windows[idx].height = 300;
	line[0].y = yo = windows[idx].height / 2;
	windows[idx].angv = 0.05;

	{
		int ws = windows[idx].width * windows[idx].width;
		int hs = windows[idx].height * windows[idx].height;
		r = sqrt(ws + hs) + 1.0;
	}

	{
		CARD32 mask = CWBackPixel | CWEventMask | CWDontPropagate;
		CARD32 values[3];
		values[0] = c->roots[0].data->white_pixel;
		values[1] = ButtonReleaseMask | ExposureMask;
		values[2] = ButtonPressMask;

		XCB_CreateWindow(c, c->roots[0].depths[0].data->depth,
			windows[idx].w.window, c->roots[0].data->root,
			/* x */ 0, /* y */ 0,
			windows[idx].width, windows[idx].height,
			/* border */ 0, InputOutput,
			/* visual */ c->roots[0].data->root_visual,
			mask, values);
	}

	XCB_MapWindow(c, windows[idx].w.window);

	XCB_CreatePixmap(c, c->roots[0].depths[0].data->depth,
		windows[idx].p.pixmap, windows[idx].w,
		windows[idx].width, windows[idx].height);

	{
		RECTANGLE rect = { 0, 0, windows[idx].width, windows[idx].height };
		XCB_PolyFillRectangle(c, windows[idx].p, white, 1, &rect);
	}

	XCB_Sync(c, 0);

	while(1)
	{
		line[1].x = xo + r * cos(theta);
		line[1].y = yo + r * sin(theta);
		XCB_PolyLine(c, CoordModeOrigin, windows[idx].p, black,
			2, line);

		line[1].x = xo + r * cos(theta + LAG);
		line[1].y = yo + r * sin(theta + LAG);
		XCB_PolyLine(c, CoordModeOrigin, windows[idx].p, white,
			2, line);

		paint(idx);
		theta += windows[idx].angv;
		while(theta > 2 * PI)
			theta -= 2 * PI;
		while(theta < 0)
			theta += 2 * PI;

		usleep(1000000 / FRAME_RATE);
	}
}

int lookup_window(WINDOW w)
{
	int i;
	for(i = 0; i < WINS; ++i)
		if(windows[i].w.window.xid == w.xid)
			return i;
	return -1;
}

void *event_thread(void *param)
{
	XCB_Event *e;
	int idx;

	while(1)
	{
		e = XCB_Wait_Event(c);
		if(!formatEvent(e))
			return 0;
		if(e->response_type == XCB_Expose)
		{
			XCB_Expose_Event *ee = (XCB_Expose_Event *) e;
			idx = lookup_window(ee->window);
			if(idx == -1)
				fprintf(stderr, "Expose on unknown window!\n");
			else
			{
				XCB_CopyArea(c, windows[idx].p, windows[idx].w,
					white, ee->x, ee->y, ee->x, ee->y,
					ee->width, ee->height);
				if(ee->count == 0)
					XCB_Flush(c);
			}
		}
		else if(e->response_type == XCB_ButtonRelease)
		{
			XCB_ButtonRelease_Event *bre = (XCB_ButtonRelease_Event *) e;
			idx = lookup_window(bre->event);
			if(idx == -1)
				fprintf(stderr, "ButtonRelease on unknown window!\n");
			else
			{
				if(bre->detail.id == Button1)
					windows[idx].angv = -windows[idx].angv;
				else if(bre->detail.id == Button4)
					windows[idx].angv += 0.001;
				else if(bre->detail.id == Button5)
					windows[idx].angv -= 0.001;
			}
		}
		free(e);
	}
}
