#include <stdlib.h>
#include <stdio.h>

#include <X11/Xlib.h>
#include <X11/XCB/xcb.h>
#include <X11/XCB/shm.h>
#include <X11/XCB/xcb_image.h>

#include "julia.h"

#define W_W 640
#define W_H 480

/* Parameters of the fractal */

/* double cr = -0.7927; */
/* double ci = 0.1609; */

/* double cr = 0.32; */
/* double ci = 0.043; */

/* double cr = -1.1380; */
/* double ci = -0.2403; */

/* double cr = -0.0986; */
/* double ci = -0.65186; */

/* double cr = -0.1225; */
/* double ci = 0.7449; */

double cr = -0.3380;
double ci = -0.6230;
double origin_x = -1.8;
double origin_y = -1.2;
double width = 3.6;
double height = 2.4;

/* Numbers of colrs in the palette */
int cmax = 316;
/* palette */
CARD32 *palette;

void
palette_julia (Data data)
{
  XCBAllocColorRep *rep;
  int               i;

  palette = (CARD32 *)malloc (sizeof (CARD32) * cmax);
  
  for (i = 0 ; i < cmax ; i++)
    {
      if (i < 128)
	rep = XCBAllocColorReply (data.conn,
				  XCBAllocColor (data.conn,
						 data.cmap,
						 i<<9, 0, 0),
				  0);
      else if (i < 255)
	rep = XCBAllocColorReply (data.conn,
				  XCBAllocColor (data.conn,
						 data.cmap,
						 65535, (i-127)<<9, 0),
				  0);
      else
	rep = XCBAllocColorReply (data.conn,
				  XCBAllocColor (data.conn,
						 data.cmap,
						 65535, 65535, (i-255)<<10),
				  0);
      
      if (!rep)
	palette[i] = 0;
      else
	palette[i] = rep->pixel;
      free (rep);
    }
  
}

void
draw_julia (Data data)
{
  XCBImage *image;
  double    zr, zi, t;
  int       c;
  int       i, j;
  
  image = XCBImageGet (data.conn, data.draw,
		       0, 0, W_W, W_H,
		       AllPlanes, data.format);
  
  for (i = 0 ; i < image->width ; i++)
    for (j = 0 ; j < image->height ; j++)
      {
	zr = origin_x + width * (double)i / (double)image->width;
	zi = origin_y + height * (double)j / (double)image->height;
	c = 0;
	while ((zr*zr + zi*zi < 4.0) &&
	       (c < cmax-1))
	  {
	    t = zr;
	    zr = zr*zr - zi*zi + cr;
	    zi = 2.0*t*zi + ci;
	    c++;
	  }
	XCBImagePutPixel (image,
			  i,j,
			  palette[c]);
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

  data.cmap = XCBCOLORMAPNew (data.conn);
  XCBCreateColormap (data.conn,
		     AllocNone,
		     data.cmap,
		     data.draw.window,
		     screen->root_visual);

  palette_julia (data);

  XCBSync (data.conn, 0); 

  while ((e = XCBWaitEvent(data.conn)))
    {
      switch (e->response_type)
	{ 
	case XCBExpose:
	  {
	    XCBCopyArea(data.conn, rect, data.draw, bgcolor,
			0, 0, 0, 0, W_W, W_H);
	    draw_julia (data);
	    XCBSync (data.conn, 0);
	    break;
	  }
	}
      free (e);
    }

  return 1;
}
