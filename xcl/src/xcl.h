#ifndef XCL_H
#define XCL_H

#include <xcb.h>
#include <X11/Xlib.h>

#define XCBConnectionOfDisplay(dpy) (*(((XCBConnection **)(dpy)) - 1))

#define XCLCASTDECL(src_t, dst_t, field)			\
	static inline dst_t XCL##dst_t(src_t src)		\
	{							\
		dst_t dst;					\
		dst.field = src;				\
		return dst;					\
	}
#define XCLXIDCASTDECL(src_t, dst_t) XCLCASTDECL(src_t, dst_t, xid)
#define XCLIDCASTDECL(src_t, dst_t) XCLCASTDECL(src_t, dst_t, id)

XCLXIDCASTDECL(Window, WINDOW)
XCLXIDCASTDECL(Pixmap, PIXMAP)
XCLXIDCASTDECL(Cursor, CURSOR)
XCLXIDCASTDECL(Font, FONT)
XCLXIDCASTDECL(GContext, GCONTEXT)
XCLXIDCASTDECL(Colormap, COLORMAP)
XCLXIDCASTDECL(Atom, ATOM)

/* For the union types, pick an arbitrary field of the union to hold the
 * Xlib XID. Assumes the bit pattern is the same regardless of the field. */
XCLCASTDECL(Drawable, DRAWABLE, window.xid)
XCLCASTDECL(Font, FONTABLE, font.xid)

XCLIDCASTDECL(VisualID, VISUALID)
XCLIDCASTDECL(Time, TIMESTAMP)
XCLIDCASTDECL(KeySym, KEYSYM)
XCLIDCASTDECL(KeyCode, KEYCODE)
XCLIDCASTDECL(CARD8, BUTTON)

#endif /* XCL_H */
