#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>

#include <sys/ipc.h>
#include <sys/shm.h>

#include <X11/Xlib.h>
#include <X11/XCB/xcb.h>
#include <X11/XCB/shm.h>
#include <X11/XCB/xcb_aux.h>
#include <X11/XCB/xcb_image.h>

#include "lissajoux.h"

#define W_W 100
#define W_H 100

double time_start;
int    loop_count;
double t_previous;
double t;
int    do_shm = 0;

XCBShmSegmentInfo shminfo;

double
get_time(void)
{
  struct timeval timev;
  
  gettimeofday(&timev, NULL);

  return (double)timev.tv_sec + (((double)timev.tv_usec) / 1000000);
}

void
draw_lissajoux (Data data)
{
  int       i, nbr;
  double    a1, a2, p1, p2;
  double    pi, period;
  double    x, y;
  
  if (do_shm)
    XCBImageSHMGet (data.conn, data.draw,
		    data.image, shminfo,
		    0, 0,
		    AllPlanes);
  else
    data.image = XCBImageGet (data.conn, data.draw,
			      0, 0, W_W, W_H,
			      AllPlanes, data.format);
  
  pi = 3.1415926535897;
  period = 2.0 * pi;
  a1 = 2.0;
  a2 = 3.0;
  p1 = 4.0*t_previous*pi*0.05;
  p2 = 0.0;

  nbr = 1000;
  for (i = 0 ; i < nbr ; i++)
      {
	x = cos (a1*i*period/nbr + p1);
	y = sin (a2*i*period/nbr + p2);
	XCBImagePutPixel (data.image,
			  (int)((double)(W_W-5)*(x+1)/2.0),
			  (int)((double)(W_H-5)*(y+1)/2.0), 65535);
      }

  p1 = 4.0*t*pi*0.05;
  p2 = 0.0;

  for (i = 0 ; i < nbr ; i++)
      {
	x = cos (a1*i*period/nbr + p1);
	y = sin (a2*i*period/nbr + p2);
	XCBImagePutPixel (data.image,
			  (int)((double)(W_W-5)*(x+1)/2.0),
			  (int)((double)(W_H-5)*(y+1)/2.0), 0);
      }

  if (do_shm)
    XCBImageSHMPut (data.conn, data.draw, data.gc,
		    data.image, shminfo,
		    0, 0, 0, 0, W_W, W_H, 0);
  else
    XCBImagePut (data.conn, data.draw, data.gc, data.image,
		 0, 0, 0, 0, W_W, W_H);
}

void
loop (Data data)
{
  loop_count++;
  t = get_time () - time_start;

  if (t <= 20.0)
    {
      draw_lissajoux (data);
    }
  else
    {
      printf("FRAME COUNT..: %i frames\n", loop_count);
      printf("TIME.........: %3.3f seconds\n", t);
      printf("AVERAGE FPS..: %3.3f fps\n", (double)loop_count / t);
      exit(0);
    }
}

/* Return 0 if shm is not availaible, 1 otherwise */
void
shm_test (Data data)
{
  XCBShmQueryVersionRep *rep;

  rep = XCBShmQueryVersionReply (data.conn,
				 XCBShmQueryVersion (data.conn),
				 NULL);
  if (rep)
    {
      CARD8 format;
      
      if (rep->shared_pixmaps && 
	  (rep->major_version > 1 || rep->minor_version > 0))
	format = rep->pixmap_format;
      else
	format = 0;
      data.image = XCBImageSHMCreate (data.conn, data.depth,
				      format, NULL, W_W, W_H);

      shminfo.shmid = shmget (IPC_PRIVATE,
			      data.image->bytes_per_line*data.image->height,
			      IPC_CREAT | 0777);
      shminfo.shmaddr = shmat (shminfo.shmid, 0, 0);
      data.image->data = shminfo.shmaddr;

      shminfo.shmseg = XCBShmSEGNew (data.conn);
      XCBShmAttach (data.conn, shminfo.shmseg,
		    shminfo.shmid, 0);
      shmctl(shminfo.shmid, IPC_RMID, 0);
    }

  if (data.image)
    {
      printf ("Use of shm.\n");
      do_shm = 1;
    }
  else
    {
      printf ("Can't use shm. Use standard functions.\n");
      shmdt (shminfo.shmaddr);		       
      shmctl (shminfo.shmid, IPC_RMID, 0);
      data.image = NULL;
    }
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
  int              try_shm;
  
  try_shm = 0;

  /* Arguments test */
  if (argc < 2)
    {
      printf ("Usage: lissajoux try_shm\n");
      printf ("         try_shm == 0: shm not used\n");
      printf ("         try_shm != 0: shm is used (if availaible)\n");
      exit (0);
    }
  if (argc >= 2)
    try_shm = atoi (argv[1]);
  if (try_shm != 0)
    try_shm = 1;

  data.conn = XCBConnectBasic ();
  screen = XCBConnSetupSuccessRepRootsIter (XCBGetSetup (data.conn)).data;
  data.depth = XCBAuxGetDepth (data.conn, screen);

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

  if (try_shm)
    shm_test (data);

  time_start = get_time ();
  t_previous = 0.0;
  while (1)
    {
      e = XCBPollForEvent(data.conn, NULL);
      if (e)
	{
	  switch (e->response_type)
	    { 
	    case XCBExpose:
	      {
		XCBCopyArea(data.conn, rect, data.draw, bgcolor,
			    0, 0, 0, 0, W_W, W_H);
		XCBSync (data.conn, 0);
		break;
	      }
	    }
	  free (e);
	}
      loop (data);
      XCBFlush (data.conn);
      t_previous = t;
    }

  return 1;
}
