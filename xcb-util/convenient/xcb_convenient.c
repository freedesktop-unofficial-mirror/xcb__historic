#include <stdio.h>
#include <stdlib.h>

#include <X11/XCB/xcb.h>

/* Connection related functions */

CARD8
xcb_connection_depth_get (XCBConnection *c,
			  XCBSCREEN     *screen)
{
  XCBDRAWABLE        drawable;
  XCBGetGeometryRep *geom;
  int                depth;

  drawable.window = screen->root;
  geom = XCBGetGeometryReply (c, XCBGetGeometry(c, drawable), 0);

  if (!geom) {
    perror ("GetGeometry(root) failed");
    exit (0);
  }
  
  depth = geom->depth;
  free (geom);

  return depth;
}

XCBSCREEN *
xcb_connection_screen_get (XCBConnection *c, int screen)
{
  XCBSCREENIter i;
  int           cur;
  
  if (!c) return NULL;
  
  i = XCBConnSetupSuccessRepRootsIter(XCBGetSetup(c));
  if (screen > i.rem - 1) return NULL; /* screen must be */
                                       /* between 0 and i.rem - 1 */
  for (cur = 0; cur <= screen; XCBSCREENNext(&i), ++cur) {}
  
  return i.data;
}

XCBVISUALTYPE *
xcb_connection_visualtype_get (XCBConnection *c,
			       int            scr,
			       XCBVISUALID    vid)
{
  XCBSCREEN        *screen;
  XCBDEPTH         *depth;
  XCBVISUALTYPEIter iter;
  int               cur;

  screen = xcb_connection_screen_get (c, scr);
  if (!screen) return NULL;
   
   iter = XCBDEPTHVisualsIter(depth);
   for (cur = 0 ; cur < iter.rem ; XCBVISUALTYPENext(&iter), ++cur)
      if (screen->root_visual.id == iter.data->visual_id.id)
	 return iter.data;

   return NULL;
}
