#ifndef __XCB_CONVENIENT_H__
#define __XCB_CONVENIENT_H__


CARD8          xcb_connection_depth_get      (XCBConnection *c,
					      XCBSCREEN     *root);

XCBSCREEN     *xcb_connection_screen_get     (XCBConnection *c,
					      int            screen);

XCBVISUALTYPE *xcb_connection_visualtype_get (XCBConnection *c,
					      int            screen,
					      XCBVISUALID    vid);


#endif /* __XCB_CONVENIENT_H__ */
