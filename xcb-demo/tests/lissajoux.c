#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include <X11/Xlib.h>
#include <X11/XCB/xcb.h>
#include <X11/XCB/shm.h>
#include <X11/XCB/xcb_image.h>

#include "lissajoux.h"

#define W_W 100
#define W_H 100

void
draw_lissajoux (Data data)
{
  XCBImage *image;
  int       i, nbr;
  double    a1, a2, p1, p2;
  double    pi, period;
  double    x, y;

  pi = 3.1415926535897;
  a1 = 1.0;
  a2 = 2.0;
  p1 = 0.0;
  p2 = 1.0;
  
  if (((2.0*pi - p1)/a1) > ((2.0*pi - p2)/a2))
    period = (2.0*pi - p1)/a1;
  else
    period = (2.0*pi - p2)/a2;
  
  image = XCBImageGet (data.conn, data.draw,
		       0, 0, W_W, W_H,
		       AllPlanes, data.format);

  nbr = 1000;
  for (i = 0 ; i < nbr ; i++)
      {
	x = sin (a1*i*period/nbr + p1);
	y = cos (a2*i*period/nbr + p2);
	XCBImagePutPixel (image,
			  (int)((double)W_W*(x+1)/2.0),
			  (int)((double)W_H*(y+1)/2.0), 0);
      }

  XCBImagePut (data.conn, data.draw, data.gc, image,
	       0, 0, 0, 0, W_W, W_H);
}

int
get_depth(XCBConnection   *c,
	  XCBSCREEN       *root)
{
  XCBDRAWABLE drawable = { root->root };
  XCBGetGeometryRep *geom;

  geom = XCBGetGeometryReply(c, XCBGetGeometry(c, drawable), 0);
  int depth;

  if(!geom)
    {
      perror("GetGeometry(root) failed");
      exit (0);
    }
  
  depth = geom->depth;
  free(geom);

  return depth;
}

int
main (int argc, char *argv[])
{
  Data             data;
  XCBSCREEN       *screen;
  XCBDRAWABLE      win;
  XCBDRAWABLE      rect;
  XCBGCONTEXT      bgcolor;
  CARD32           mask;
  CARD32           valgc[2];
  CARD32           valwin[3];
  XCBRECTANGLE     rect_coord = { 0, 0, W_W, W_H};
  XCBGenericEvent *e;
  
  data.conn = XCBConnectBasic ();
  screen = XCBConnSetupSuccessRepRootsIter (XCBGetSetup (data.conn)).data;
  data.depth = get_depth (data.conn, screen);

  win.window = screen->root;

  data.gc = XCBGCONTEXTNew (data.conn);
  mask = GCForeground | GCGraphicsExposures;
  valgc[0] = screen->black_pixel;
  valgc[1] = 0; /* no graphics exposures */
  XCBCreateGC (data.conn, data.gc, win, mask, valgc);

  bgcolor = XCBGCONTEXTNew (data.conn);
  mask = GCForeground | GCGraphicsExposures;
  valgc[0] = screen->white_pixel;
  valgc[1] = 0; /* no graphics exposures */
  XCBCreateGC (data.conn, bgcolor, win, mask, valgc);

  data.draw.window = XCBWINDOWNew (data.conn);
  mask = XCBCWBackPixel | XCBCWEventMask | XCBCWDontPropagate;
  valwin[0] = screen->white_pixel;
  valwin[1] = KeyPressMask | ButtonReleaseMask | ExposureMask;
  valwin[2] = ButtonPressMask;
  XCBCreateWindow (data.conn, 0,
		   data.draw.window,
		   screen->root,
		   0, 0, W_W, W_H,
		   10,
		   InputOutput,
		   screen->root_visual,
		   mask, valwin);
  XCBMapWindow (data.conn, data.draw.window);

  rect.pixmap = XCBPIXMAPNew (data.conn);
  XCBCreatePixmap (data.conn, data.depth,
		   rect.pixmap, data.draw,
		   W_W, W_H);
  XCBPolyFillRectangle(data.conn, rect, bgcolor, 1, &rect_coord);

  XCBMapWindow (data.conn, data.draw.window);

  data.format = ZPixmap;
  XCBSync (data.conn, 0); 

  while ((e = XCBWaitEvent(data.conn)))
    {
      switch (e->response_type)
	{ 
	case XCBExpose:
	  {
	    XCBCopyArea(data.conn, rect, data.draw, bgcolor,
			0, 0, 0, 0, W_W, W_H);
	    draw_lissajoux (data);
	    XCBSync (data.conn, 0);
	    break;
	  }
	}
      free (e);
    }

  return 1;
}
