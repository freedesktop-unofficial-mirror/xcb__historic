_C`'#include <assert.h>
_C`'#include <stdlib.h>
_C
_H`'#include "xcb_conn.h"
_C`'#include "xp_core.h"

FUNCTION(`', `int XP_Flush', `XCB_Connection *c', `
    XCB_Connection_Lock(c);
    XCB_Flush(c);
    XCB_Connection_Unlock(c);
    return 1;
')

FUNCTION(`', `int XP_Sync', `XCB_Connection *c', `
    XCB_InputFocus_cookie cookie = XP_GetInputFocus(c);
    XP_InputFocus_Reply *reply = XP_InputFocus_Get_Reply(c, cookie);
    free(reply);
    return (reply != 0);
')

VALUE(XP_CreateWindowValues, `
VALUECODE(0x00000001, XP_PIXMAP, background_pixmap)
VALUECODE(0x00000002, XP_CARD32, background_pixel)
VALUECODE(0x00000004, XP_PIXMAP, border_pixmap)
VALUECODE(0x00000008, XP_CARD32, border_pixel)
VALUECODE(0x00000010, XP_BITGRAVITY, bit_gravity)
VALUECODE(0x00000020, XP_WINGRAVITY, win_gravity)
VALUECODE(0x00000040, XP_CARD8, backing_store)
VALUECODE(0x00000080, XP_CARD32, backing_planes)
VALUECODE(0x00000100, XP_CARD32, backing_pixel)
VALUECODE(0x00000200, XP_BOOL, override_redirect)
VALUECODE(0x00000400, XP_BOOL, save_under)
VALUECODE(0x00000800, XP_SETofEVENT, event_mask)
VALUECODE(0x00001000, XP_SETofDEVICEEVENT, do_not_propagate_mask)
VALUECODE(0x00002000, XP_COLORMAP, colormap)
VALUECODE(0x00004000, XP_CURSOR, cursor)
')
_H
REQUEST(void, CreateWindow, 1, depth, `
    PARAM(XP_WINDOW, `wid')
    PARAM(XP_WINDOW, `parent')
    PARAM(XP_INT16, `x')
    PARAM(XP_INT16, `y')
    PARAM(XP_CARD16, `width')
    PARAM(XP_CARD16, `height')
    PARAM(XP_CARD16, `border_width')
    PARAM(XP_CARD16, `class')
    PARAM(XP_VISUALID, `visual')
    BITMASKPARAM(XP_CARD32, `values')
    VALUEPARAM(XP_CreateWindowValues, `values')
')

REQUEST(void, ChangeWindowAttributes, 2, unused, `
    PARAM(XP_WINDOW, `window')
    BITMASKPARAM(XP_CARD32, `values')
    VALUEPARAM(XP_CreateWindowValues, `values')
')

REPLY(WindowAttributes, backing_store, `
    FIELD(XP_VISUALID, `visual')
    FIELD(XP_CARD16, `class')
    FIELD(XP_BITGRAVITY, `bit_gravity')
    FIELD(XP_WINGRAVITY, `win_gravity')
    FIELD(XP_CARD32, `backing_planes')
    FIELD(XP_CARD32, `backing_pixel')
    FIELD(XP_BOOL, `save_under')
    FIELD(XP_BOOL, `map_is_installed')
    FIELD(XP_CARD8, `map_state')
    FIELD(XP_BOOL, `override_redirect')
    FIELD(XP_COLORMAP, `colormap')
    FIELD(XP_SETofEVENT, `all_event_masks')
    FIELD(XP_SETofEVENT, `your_event_mask')
    FIELD(XP_SETofDEVICEEVENT, `do_not_propagate_mask')
')

REQUEST(WindowAttributes, GetWindowAttributes, 3, unused, `
    PARAM(XP_WINDOW, `window')
')

REQUEST(void, DestroyWindow, 4, unused, `PARAM(XP_WINDOW, `window')')

REQUEST(void, DestroySubwindows, 5, unused, `PARAM(XP_WINDOW, `window')')

REQUEST(void, ChangeSaveSet, 6, mode, `PARAM(XP_WINDOW, `window')')

REQUEST(void, ReparentWindow, 7, unused, `
    PARAM(XP_WINDOW, `window')
    PARAM(XP_WINDOW, `parent')
    PARAM(XP_INT16, `x')
    PARAM(XP_INT16, `y')
')

REQUEST(void, MapWindow, 8, unused, `PARAM(XP_WINDOW, `window')')

REQUEST(void, MapSubwindows, 9, unused, `PARAM(XP_WINDOW, `window')')

REQUEST(void, UnmapWindow, 10, unused, `PARAM(XP_WINDOW, `window')')

REQUEST(void, UnmapSubwindows, 11, unused, `PARAM(XP_WINDOW, `window')')

VALUE(XP_ConfigureWindowValues, `
VALUECODE(0x0001, XP_INT16, `x')
VALUECODE(0x0002, XP_INT16, `y')
VALUECODE(0x0004, XP_CARD16, `width')
VALUECODE(0x0008, XP_CARD16, `height')
VALUECODE(0x0010, XP_CARD16, `border_width')
VALUECODE(0x0020, XP_WINDOW, `sibling')
VALUECODE(0x0040, XP_CARD8, `stack_mode')
')
_H
REQUEST(void, ConfigureWindow, 12, unused, `
    PARAM(XP_WINDOW, `window')
    BITMASKPARAM(XP_CARD16, `values')
    PAD(2)
    VALUEPARAM(XP_ConfigureWindowValues, `values')
')

REQUEST(void, CirculateWindow, 13, direction, `PARAM(XP_WINDOW, `window')')

REPLY(Geometry, depth, `
    FIELD(XP_WINDOW, `root')
    FIELD(XP_INT16, `x')
    FIELD(XP_INT16, `y')
    FIELD(XP_CARD16, `width')
    FIELD(XP_CARD16, `height')
    FIELD(XP_CARD16, `border_width')
')

REQUEST(Geometry, GetGeometry, 14, unused, `PARAM(XP_DRAWABLE, `drawable')')

REPLY(Tree, unused, `
    FIELD(XP_WINDOW, `root')
    FIELD(XP_WINDOW, `parent')
    FIELD(XP_CARD16, `children_length')
    PAD(14)
    LISTFIELD(XP_WINDOW, `children', `children_length')
')

REQUEST(Tree, QueryTree, 15, unused, `PARAM(XP_WINDOW, `window')')

REQUEST(void, ChangeProperty, 18, mode, `
    PARAM(XP_WINDOW, `window')
    PARAM(XP_ATOM, `property')
    PARAM(XP_ATOM, `type')
    PARAM(XP_CARD8, `format')
    PAD(3)
    PARAM(XP_CARD32, `data_length')
    LISTPARAM(XP_BYTE, `data', `data_length * format / 8')
')

REQUEST(void, DeleteProperty, 19, unused, `
    PARAM(XP_WINDOW, `window')
    PARAM(XP_ATOM, `property')
')

REQUEST(void, SetSelectionOwner, 22, unused, `
    PARAM(XP_WINDOW, `owner')
    PARAM(XP_ATOM, `selection')
    PARAM(XP_TIMESTAMP, `time')
')

REQUEST(void, ConvertSelection, 24, unused, `
    PARAM(XP_WINDOW, `requestor')
    PARAM(XP_ATOM, `selection')
    PARAM(XP_ATOM, `target')
    PARAM(XP_ATOM, `property')
    PARAM(XP_TIMESTAMP, `time')
')

REQUEST(void, SendEvent, 25, propagate, `
    PARAM(XP_WINDOW, `destination')
    PARAM(XP_SETofEVENT, `event_mask')
    dnl FIXME: standard event format goes here
')

REQUEST(void, UngrabPointer, 27, unused, `
    PARAM(XP_TIMESTAMP, `time')
')

REQUEST(void, GrabButton, 28, owner_events, `
    PARAM(XP_WINDOW, `grab_window')
    PARAM(XP_SETofPOINTEREVENT, `event_mask')
    PARAM(XP_CARD8, `pointer_mode')
    PARAM(XP_CARD8, `keyboard_mode')
    PARAM(XP_WINDOW, `confine_to')
    PARAM(XP_CURSOR, `cursor')
    PARAM(XP_BUTTON, `button')
    PAD(1)
    PARAM(XP_SETofKEYMASK, `modifiers')
')

REQUEST(void, UngrabButton, 29, button, `
    PARAM(XP_WINDOW, `grab_window')
    PARAM(XP_SETofKEYMASK, `modifiers')
    PAD(2)
')

REQUEST(void, ChangeActivePointerGrab, 30, unused, `
    PARAM(XP_CURSOR, `cursor')
    PARAM(XP_TIMESTAMP, `time')
    PARAM(XP_SETofPOINTEREVENT, `event_mask')
    PAD(2)
')

REQUEST(void, UngrabKeyboard, 32, unused, `
    PARAM(XP_TIMESTAMP, `time')
')

REQUEST(void, GrabKey, 33, owner_events, `
    PARAM(XP_WINDOW, `grab_window')
    PARAM(XP_SETofKEYMASK, `modifiers')
    PARAM(XP_KEYCODE, `key')
    PARAM(XP_CARD8, `pointer_mode')
    PARAM(XP_CARD8, `keyboard_mode')
    PAD(3)
')

REQUEST(void, UngrabKey, 34, key, `
    PARAM(XP_WINDOW, `grab_window')
    PARAM(XP_SETofKEYMASK, `modifiers')
    PAD(2)
')

REQUEST(void, AllowEvents, 35, mode, `
    PARAM(XP_TIMESTAMP, `time')
')

REQUEST(void, GrabServer, 36, unused)

REQUEST(void, UngrabServer, 37, unused)

REQUEST(void, WarpPointer, 41, unused, `
    PARAM(XP_WINDOW, `src_window')
    PARAM(XP_WINDOW, `dst_window')
    PARAM(XP_INT16, `src_x')
    PARAM(XP_INT16, `src_y')
    PARAM(XP_CARD16, `src_width')
    PARAM(XP_CARD16, `src_height')
    PARAM(XP_INT16, `dst_x')
    PARAM(XP_INT16, `dst_y')
')

REQUEST(void, SetInputFocus, 42, revert_to, `
    PARAM(XP_WINDOW, `focus')
    PARAM(XP_TIMESTAMP, `time')
')

REPLY(InputFocus, revert_to, `
    FIELD(XP_WINDOW, `focus')
')

REQUEST(InputFocus, GetInputFocus, 43, unused)

REQUEST(void, OpenFont, 45, unused, `
    PARAM(XP_FONT, `fid')
    STRLENPARAM(XP_CARD16, `name', `name_length')
    PAD(2)
    LISTPARAM(char, `name', `name_length')
')

REQUEST(void, CloseFont, 46, unused, `PARAM(XP_FONT, `font')')

REPLY(TextExtents, draw_direction, `
    FIELD(XP_INT16, `font_ascent')
    FIELD(XP_INT16, `font_descent')
    FIELD(XP_INT16, `overall_ascent')
    FIELD(XP_INT16, `overall_descent')
    FIELD(XP_INT32, `overall_width')
    FIELD(XP_INT32, `overall_left')
    FIELD(XP_INT32, `overall_right')
')

dnl The minor byte is not really unused, but we can calculate it for the
dnl client. Just to be nice.
REQUEST(TextExtents, QueryTextExtents, 48, unused, `
    PARAM(XP_FONTABLE, `font')
dnl string_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 string_length`'popdiv()
    LISTPARAM(XP_CHAR2B, `string', `string_length')
pushdiv(_outdiv)pushdef(`_index', 1)dnl
PACK(XP_BOOL, `(XP_PAD(string_length * 'SIZEOF(XP_CHAR2B)`) == 2) ? 1 : 0')
popdef(`_index')popdiv()
')

VALUE(XP_CreateGCValues, `
VALUECODE(0x00000001, XP_CARD8, `function')
VALUECODE(0x00000002, XP_CARD32, `plane_mask')
VALUECODE(0x00000004, XP_CARD32, `foreground')
VALUECODE(0x00000008, XP_CARD32, `background')
VALUECODE(0x00000010, XP_CARD16, `line_width')
VALUECODE(0x00000020, XP_CARD8, `line_style')
VALUECODE(0x00000040, XP_CARD8, `cap_style')
VALUECODE(0x00000080, XP_CARD8, `join_style')
VALUECODE(0x00000100, XP_CARD8, `fill_style')
VALUECODE(0x00000200, XP_CARD8, `fill_rule')
VALUECODE(0x00000400, XP_PIXMAP, `tile')
VALUECODE(0x00000800, XP_PIXMAP, `stipple')
VALUECODE(0x00001000, XP_INT16, `tile_stipple_x_origin')
VALUECODE(0x00002000, XP_INT16, `tile_stipple_y_origin')
VALUECODE(0x00004000, XP_FONT, `font')
VALUECODE(0x00008000, XP_CARD8, `subwindow_mode')
VALUECODE(0x00010000, XP_BOOL, `graphics_exposures')
VALUECODE(0x00020000, XP_INT16, `clip_x_origin')
VALUECODE(0x00040000, XP_INT16, `clip_y_origin')
VALUECODE(0x00080000, XP_PIXMAP, `clip_mask')
VALUECODE(0x00100000, XP_CARD16, `dash_offset')
VALUECODE(0x00200000, XP_CARD8, `dashes')
VALUECODE(0x00400000, XP_CARD8, `arc_mode')
')
_H
REQUEST(void, CreateGC, 55, unused, `
    PARAM(XP_GCONTEXT, `cid')
    PARAM(XP_DRAWABLE, `drawable')
    BITMASKPARAM(XP_CARD32, `values')
    VALUEPARAM(XP_CreateGCValues, `values')
')

REQUEST(void, ChangeGC, 56, unused, `
    PARAM(XP_GCONTEXT, `gc')
    BITMASKPARAM(XP_CARD32, `values')
    VALUEPARAM(XP_CreateGCValues, `values')
')

REQUEST(void, CopyGC, 57, unused, `
    PARAM(XP_GCONTEXT, `src_gc')
    PARAM(XP_GCONTEXT, `dst_gc')
    PARAM(XP_CARD32, `value_mask')
')

REQUEST(void, SetDashes, 58, unused, `
    PARAM(XP_GCONTEXT, `gc')
    PARAM(XP_CARD16, `dash_offset')
    PARAM(XP_CARD16, `dashes_length')
    LISTPARAM(XP_CARD8, `dashes', `dashes_length')
')

REQUEST(void, SetClipRectangles, 59, ordering, `
    PARAM(XP_GCONTEXT, `gc')
    PARAM(XP_INT16, `clip_x_origin')
    PARAM(XP_INT16, `clip_y_origin')
dnl rectangles_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 rectangles_length`'popdiv()
    LISTPARAM(XP_RECTANGLE, `rectangles', `rectangles_length')
')

REQUEST(void, FreeGC, 60, unused, `PARAM(XP_GCONTEXT, `gc')')

REQUEST(void, ClearArea, 61, exposures, `
    PARAM(XP_WINDOW, `window')
    PARAM(XP_INT16, `x')
    PARAM(XP_INT16, `y')
    PARAM(XP_CARD16, `width')
    PARAM(XP_CARD16, `height')
')

REQUEST(void, CopyArea, 62, unused, `
    PARAM(XP_DRAWABLE, `src_drawable')
    PARAM(XP_DRAWABLE, `dst_drawable')
    PARAM(XP_GCONTEXT, `gc')
    PARAM(XP_INT16, `src_x')
    PARAM(XP_INT16, `src_y')
    PARAM(XP_INT16, `dst_x')
    PARAM(XP_INT16, `dst_y')
    PARAM(XP_CARD16, `width')
    PARAM(XP_CARD16, `height')
')

REQUEST(void, CopyPlane, 63, unused, `
    PARAM(XP_DRAWABLE, `src_drawable')
    PARAM(XP_DRAWABLE, `dst_drawable')
    PARAM(XP_GCONTEXT, `gc')
    PARAM(XP_INT16, `src_x')
    PARAM(XP_INT16, `src_y')
    PARAM(XP_INT16, `dst_x')
    PARAM(XP_INT16, `dst_y')
    PARAM(XP_CARD16, `width')
    PARAM(XP_CARD16, `height')
    PARAM(XP_CARD32, `bit_plane')
')

REQUEST(void, PolyPoint, 64, coordinate_mode, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
dnl points_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 points_length`'popdiv()
    LISTPARAM(XP_POINT, `points', `points_length')
')

REQUEST(void, PolyLine, 65, coordinate_mode, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
dnl points_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 points_length`'popdiv()
    LISTPARAM(XP_POINT, `points', `points_length')
')

STRUCT(XP_SEGMENT, `
    FIELD(XP_INT16, `x1')
    FIELD(XP_INT16, `y1')
    FIELD(XP_INT16, `x2')
    FIELD(XP_INT16, `y2')
')

REQUEST(void, PolySegment, 66, unused, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
dnl segments_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 segments_length`'popdiv()
    LISTPARAM(XP_SEGMENT, `segments', `segments_length')
')

REQUEST(void, PolyRectangle, 67, unused, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
dnl rectangles_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 rectangles_length`'popdiv()
    LISTPARAM(XP_RECTANGLE, `rectangles', `rectangles_length')
')

REQUEST(void, PolyArc, 68, unused, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
dnl arcs_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 arcs_length`'popdiv()
    LISTPARAM(XP_ARC, `arcs', `arcs_length')
')

REQUEST(void, FillPoly, 69, unused, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
    PARAM(XP_CARD8, `shape')
    PARAM(XP_CARD8, `coordinate_mode')
    PAD(2)
dnl points_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 points_length`'popdiv()
    LISTPARAM(XP_POINT, `points', `points_length')
')

REQUEST(void, PolyFillRectangle, 70, unused, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
dnl rectangles_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 rectangles_length`'popdiv()
    LISTPARAM(XP_RECTANGLE, `rectangles', `rectangles_length')
')

REQUEST(void, PolyFillArc, 71, unused, `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
dnl arcs_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 arcs_length`'popdiv()
    LISTPARAM(XP_ARC, `arcs', `arcs_length')
')

REQUEST(void, PutImage, 72, `format', `
    PARAM(XP_DRAWABLE, `drawable')
    PARAM(XP_GCONTEXT, `gc')
    PARAM(XP_CARD16, `width')
    PARAM(XP_CARD16, `height')
    PARAM(XP_INT16, `dst_x')
    PARAM(XP_INT16, `dst_y')
    PARAM(XP_CARD8, `left_pad')
    PARAM(XP_CARD8, `depth')
    PAD(2)
dnl data_length is implicit in the protocol, but we need to know it :)
pushdiv(_parmdiv), XP_CARD16 data_length`'popdiv()
    LISTPARAM(XP_BYTE, `data', `data_length')
')

dnl FIXME: `percent' is supposed to be XP_INT8... :(
REQUEST(void, Bell, 104, percent)

dnl FIXME: NoOperation should allow specifying payload length
dnl but geez, malloc()ing a 262140 byte buffer just so I have something
dnl to hand to write(2) seems silly...!
REQUEST(void, NoOperation, 127, unused)
