#include "xp_core.h"
#include "reply_formats.h"
#include <math.h>
#include <stdlib.h> /* for free(3) */
#include <unistd.h> /* for usleep(3) */
#include <pthread.h>

#define JUMP 0.05 /* angle increment */
#define LAG 0.3 /* lag angle for the follow line */

/* If I've done my math right, Linux maxes out at 100 fps on Intel (1000 fps
 * on Alpha) due to the granularity of the kernel timer. */
#define FRAME_RATE 100.0 /* frames per second */

#define PI 3.14159265

static XCB_Connection *c;
static GContext white, black;

#define WINS 5
static struct { Window w; Pixmap p; CARD16 width; CARD16 height; } windows[WINS];

void *run(void *param);
void *event_thread(void *param);

int main()
{
	pthread_t thr;
	int i;

	CARD32 mask = GCForeground | GCGraphicsExposures;
	CARD32 values[2];

	c = XCB_Connect_Basic();
	white = XCB_Generate_ID(c);
	black = XCB_Generate_ID(c);

	pthread_create(&thr, 0, event_thread, 0);

	values[1] = 0; /* no graphics exposures */

	values[0] = c->roots[0].data->whitePixel;
	XCB_CreateGC(c, white, c->roots[0].data->windowId, mask, values);

	values[0] = c->roots[0].data->blackPixel;
	XCB_CreateGC(c, black, c->roots[0].data->windowId, mask, values);

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
	XCB_Flush(c);
}

void *run(void *param)
{
	int idx = (int)param;
	CARD32 mask = 0;
	CARD32 values[1];

	int xo, yo;
	double r, theta = 0;

	xPoint line[2];

	windows[idx].w = XCB_Generate_ID(c);
	windows[idx].p = XCB_Generate_ID(c);
	windows[idx].width = 300;
	line[0].x = xo = windows[idx].width / 2;
	windows[idx].height = 300;
	line[0].y = yo = windows[idx].height / 2;

	{
		int ws = windows[idx].width * windows[idx].width;
		int hs = windows[idx].height * windows[idx].height;
		r = sqrt(ws + hs) + 1.0;
	}

	mask |= CWBackPixel;
	values[0] = c->roots[0].data->whitePixel;

	XCB_CreateWindow(c, c->roots[0].depths[0].data->depth,
		windows[idx].w, c->roots[0].data->windowId,
		/* x */ 0, /* y */ 0, windows[idx].width, windows[idx].height,
		/* border */ 0, InputOutput,
		/* visual */ c->roots[0].data->rootVisualID, mask, values);
	XCB_MapWindow(c, windows[idx].w);

	XCB_CreatePixmap(c, c->roots[0].depths[0].data->depth,
		windows[idx].p, windows[idx].w,
		windows[idx].width, windows[idx].height);

	// XCB_Sync(c, 0);

	{
		xRectangle rects[1] = { { 0, 0, windows[idx].width, windows[idx].height } };
		XCB_PolyFillRectangle(c, windows[idx].p, white, 1, rects);
	}

	while(1)
	{
		usleep(1000000 / FRAME_RATE);

		line[1].x = xo + r * cos(theta);
		line[1].y = yo + r * sin(theta);
		XCB_PolyLine(c, CoordModeOrigin, windows[idx].p, black,
			2, line);

		line[1].x = xo + r * cos(theta + LAG);
		line[1].y = yo + r * sin(theta + LAG);
		XCB_PolyLine(c, CoordModeOrigin, windows[idx].p, white,
			2, line);

		paint(idx);
		theta += JUMP;
		while(theta > 2 * PI)
			theta -= 2 * PI;
	}
}

void *event_thread(void *param)
{
	XCB_Event *e;

	while(1)
	{
		e = XCB_Wait_Event(c);
		if(!formatEvent(e))
			return 0;
		free(e);
	}
}
