XCBGEN(XP_CORE)
SOURCEONLY(`dnl
#include <assert.h>
#include <stdlib.h>
#include <stdio.h> /* for perror */
#include <string.h>
dnl')
HEADERONLY(`dnl
#include "xcb_conn.h"

typedef char CHAR2B[2];


/* Core event and error types */

EVENT(KeyPress, 2, `
    REPLY(KeyCode, `detail')
    REPLY(Time, `time')
    REPLY(Window, `root')
    REPLY(Window, `event')
    REPLY(Window, `child')
    REPLY(INT16, `root_x')
    REPLY(INT16, `root_y')
    REPLY(INT16, `event_x')
    REPLY(INT16, `event_y')
    REPLY(CARD16, `state')
    REPLY(BOOL, `same_screen')
')
EVENTCOPY(KeyRelease, 3, KeyPress)
EVENT(ButtonPress, 4, `
    REPLY(CARD8, `detail')
    REPLY(Time, `time')
    REPLY(Window, `root')
    REPLY(Window, `event')
    REPLY(Window, `child')
    REPLY(INT16, `root_x')
    REPLY(INT16, `root_y')
    REPLY(INT16, `event_x')
    REPLY(INT16, `event_y')
    REPLY(CARD16, `state')
    REPLY(BOOL, `same_screen')
')
EVENTCOPY(ButtonRelease, 5, ButtonPress)
EVENT(MotionNotify, 6, `
    REPLY(BYTE, `detail')
    REPLY(Time, `time')
    REPLY(Window, `root')
    REPLY(Window, `event')
    REPLY(Window, `child')
    REPLY(INT16, `root_x')
    REPLY(INT16, `root_y')
    REPLY(INT16, `event_x')
    REPLY(INT16, `event_y')
    REPLY(CARD16, `state')
    REPLY(BOOL, `same_screen')
')
EVENT(EnterNotify, 7, `
    REPLY(BYTE, `detail')
    REPLY(Time, `time')
    REPLY(Window, `root')
    REPLY(Window, `event')
    REPLY(Window, `child')
    REPLY(INT16, `root_x')
    REPLY(INT16, `root_y')
    REPLY(INT16, `event_x')
    REPLY(INT16, `event_y')
    REPLY(CARD16, `state')
    REPLY(BYTE, `mode')
    REPLY(BYTE, `same_screen_focus')
')
EVENTCOPY(LeaveNotify, 8, EnterNotify)
EVENT(FocusIn, 9, `
    REPLY(BYTE, `detail')
    REPLY(Window, `event')
    REPLY(BYTE, `mode')
')
EVENTCOPY(FocusOut, 10, FocusIn)
EVENT(KeymapNotify, 11, `
    ARRAYFIELD(CARD8, `keys', 31)
')
EVENT(Expose, 12, `
    PAD(1)
    REPLY(Window, `window')
    REPLY(CARD16, `x')
    REPLY(CARD16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `count')
')
EVENT(GraphicsExposure, 13, `
    PAD(1)
    REPLY(Drawable, `drawable')
    REPLY(CARD16, `x')
    REPLY(CARD16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `minor_opcode')
    REPLY(CARD16, `count')
    REPLY(CARD8, `major_opcode')
')
EVENT(NoExposure, 14, `
    PAD(1)
    REPLY(Drawable, `drawable')
    REPLY(CARD16, `minor_opcode')
    REPLY(CARD8, `major_opcode')
')
EVENT(VisibilityNotify, 15, `
    PAD(1)
    REPLY(Window, `window')
    REPLY(BYTE, `state')
')
EVENT(CreateNotify, 16, `
    PAD(1)
    REPLY(Window, `parent')
    REPLY(Window, `window')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
    REPLY(BOOL, `override_redirect')
')
EVENT(DestroyNotify, 17, `
    PAD(1)
    REPLY(Window, `event')
    REPLY(Window, `window')
')
EVENT(UnmapNotify, 18, `
    PAD(1)
    REPLY(Window, `event')
    REPLY(Window, `window')
    REPLY(BOOL, `from_configure')
')
EVENT(MapNotify, 19, `
    PAD(1)
    REPLY(Window, `event')
    REPLY(Window, `window')
    REPLY(BOOL, `override_redirect')
')
EVENT(MapRequest, 20, `
    PAD(1)
    REPLY(Window, `parent')
    REPLY(Window, `window')
')
EVENT(ReparentNotify, 21, `
    PAD(1)
    REPLY(Window, `event')
    REPLY(Window, `window')
    REPLY(Window, `parent')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(BOOL, `override_redirect')
')
EVENT(ConfigureNotify, 22, `
    PAD(1)
    REPLY(Window, `event')
    REPLY(Window, `window')
    REPLY(Window, `above_sibling')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
    REPLY(BOOL, `override_redirect')
')
EVENT(ConfigureRequest, 23, `
    REPLY(BYTE, `stack_mode')
    REPLY(Window, `parent')
    REPLY(Window, `window')
    REPLY(Window, `sibling')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
    REPLY(CARD16, `value_mask')
')
EVENT(GravityNotify, 24, `
    PAD(1)
    REPLY(Window, `event')
    REPLY(Window, `window')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
')
EVENT(ResizeRequest, 25, `
    PAD(1)
    REPLY(Window, `window')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
')
EVENT(CirculateNotify, 26, `
    PAD(1)
    REPLY(Window, `event')
    REPLY(Window, `window')
    PAD(4)
    REPLY(BYTE, `place')
')
EVENTCOPY(CirculateRequest, 27, CirculateNotify)
EVENT(PropertyNotify, 28, `
    PAD(1)
    REPLY(Window, `window')
    REPLY(Atom, `atom')
    REPLY(Time, `time')
    REPLY(BYTE, `state')
')
EVENT(SelectionClear, 29, `
    PAD(1)
    REPLY(Time, `time')
    REPLY(Window, `owner')
    REPLY(Atom, `selection')
')
EVENT(SelectionRequest, 30, `
    PAD(1)
    REPLY(Time, `time')
    REPLY(Window, `owner')
    REPLY(Window, `requestor')
    REPLY(Atom, `selection')
    REPLY(Atom, `target')
    REPLY(Atom, `property')
')
EVENT(SelectionNotify, 31, `
    PAD(1)
    REPLY(Time, `time')
    REPLY(Window, `requestor')
    REPLY(Atom, `selection')
    REPLY(Atom, `target')
    REPLY(Atom, `property')
')
EVENT(ColormapNotify, 32, `
    PAD(1)
    REPLY(Window, `window')
    REPLY(Colormap, `colormap')
    REPLY(BOOL, `_new')
    REPLY(BYTE, `state')
')
EVENT(ClientMessage, 33, `
    REPLY(CARD8, `format')
    REPLY(Window, `window')
    REPLY(Atom, `type')
')
EVENT(MappingNotify, 34, `
    PAD(1)
    REPLY(BYTE, `request')
    REPLY(KeyCode, `first_keycode')
    REPLY(CARD8, `count')
')
ERROR(Request, 1, `
    REPLY(CARD32, `bad_value')
    REPLY(CARD16, `minor_opcode')
    REPLY(CARD8, `major_opcode')
')
ERROR(Value, 2, `
    REPLY(CARD32, `bad_value')
    REPLY(CARD16, `minor_opcode')
    REPLY(CARD8, `major_opcode')
')
ERRORCOPY(Window, 3, Value)
ERRORCOPY(Pixmap, 4, Value)
ERRORCOPY(Atom, 5, Value)
ERRORCOPY(Cursor, 6, Value)
ERRORCOPY(Font, 7, Value)
ERRORCOPY(Match, 8, Request)
ERRORCOPY(Drawable, 9, Value)
ERRORCOPY(Access, 10, Request)
ERRORCOPY(Alloc, 11, Request)
ERRORCOPY(Colormap, 12, Value)
ERRORCOPY(GContext, 13, Value)
ERRORCOPY(IDChoice, 14, Value)
ERRORCOPY(Name, 15, Request)
ERRORCOPY(Length, 16, Request)
ERRORCOPY(Implementation, 17, Request)
')dnl end HEADERONLY

/* The requests, in major number order. */
/* It is the caller's responsibility to free returned XCB_*_Rep objects. */

VOIDREQUEST(CreateWindow, `
    OPCODE(1)
    PARAM(CARD8, `depth')
    PARAM(Window, `wid')
    PARAM(Window, `parent')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD16, `border_width')
    PARAM(CARD16, `class')
    PARAM(VisualID, `visual')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(ChangeWindowAttributes, `
    OPCODE(2)
    PAD(1)
    PARAM(Window, `window')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

REQUEST(GetWindowAttributes, `
    OPCODE(3)
    PAD(1)
    PARAM(Window, `window')
', `
    REPLY(CARD8, `backing_store')
    REPLY(VisualID, `visual')
    REPLY(CARD16, `_class')
    REPLY(CARD8, `bit_gravity')
    REPLY(CARD8, `win_gravity')
    REPLY(CARD32, `backing_planes')
    REPLY(CARD32, `backing_pixel')
    REPLY(BOOL, `save_under')
    REPLY(BOOL, `map_is_installed')
    REPLY(CARD8, `map_state')
    REPLY(BOOL, `override_redirect')
    REPLY(Colormap, `colormap')
    REPLY(CARD32, `all_event_masks')
    REPLY(CARD32, `your_event_mask')
    REPLY(CARD16, `do_not_propagate_mask')
')

VOIDREQUEST(DestroyWindow, `
    OPCODE(4)
    PAD(1)
    PARAM(Window, `window')
')

VOIDREQUEST(DestroySubwindows, `
    OPCODE(5)
    PAD(1)
    PARAM(Window, `window')
')

VOIDREQUEST(ChangeSaveSet, `
    OPCODE(6)
    PARAM(BYTE, `mode')
    PARAM(Window, `window')
')

VOIDREQUEST(ReparentWindow, `
    OPCODE(7)
    PAD(1)
    PARAM(Window, `window')
    PARAM(Window, `parent')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
')

VOIDREQUEST(MapWindow, `
    OPCODE(8)
    PAD(1)
    PARAM(Window, `window')
')

VOIDREQUEST(MapSubwindows, `
    OPCODE(9)
    PAD(1)
    PARAM(Window, `window')
')

VOIDREQUEST(UnmapWindow, `
    OPCODE(10)
    PAD(1)
    PARAM(Window, `window')
')

VOIDREQUEST(UnmapSubwindows, `
    OPCODE(11)
    PAD(1)
    PARAM(Window, `window')
')

VOIDREQUEST(ConfigureWindow, `
    OPCODE(12)
    PAD(1)
    PARAM(Window, `window')
    VALUEPARAM(CARD16, `value_mask', `value_list')
')

VOIDREQUEST(CirculateWindow, `
    OPCODE(13)
    PARAM(CARD8, `direction')
    PARAM(Window, `window')
')

REQUEST(GetGeometry, `
    OPCODE(14)
    PAD(1)
    PARAM(Drawable, `drawable')
', `
    REPLY(CARD8, `depth')
    REPLY(Window, `root')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
')

REQUEST(QueryTree, `
    OPCODE(15)
    PAD(1)
    PARAM(Window, `window')
', `
    PAD(1)
    REPLY(Window, `root')
    REPLY(Window, `parent')
    REPLY(CARD16, `children_len')
    PAD(14)
    ARRAYREPLY(Window, `children')
')

REQUEST(InternAtom, `
    OPCODE(16)
    PARAM(BOOL, `only_if_exists')
    EXPRFIELD(CARD16, `name_len', `strlen(name)')
    PAD(2)
    LISTPARAM(char, `name', `name_len')
', `
    PAD(1)
    REPLY(Atom, `atom')
')

REQUEST(GetAtomName, `
    OPCODE(17)
    PAD(1)
    PARAM(Atom, `atom')
', `
    PAD(1)
    REPLY(CARD16, `name_len')
    PAD(22)
    ARRAYREPLY(CARD8, `name')
')

VOIDREQUEST(ChangeProperty, `
    OPCODE(18)
    PARAM(CARD8, `mode')
    PARAM(Window, `window')
    PARAM(Atom, `property')
    PARAM(Atom, `type')
    PARAM(CARD8, `format')
    PAD(3)
    PARAM(CARD32, `data_len')
    LISTPARAM(BYTE, `data', `data_len * format / 8')
')

VOIDREQUEST(DeleteProperty, `
    OPCODE(19)
    PAD(1)
    PARAM(Window, `window')
    PARAM(Atom, `property')
')

REQUEST(GetProperty, `
    OPCODE(20)
    PARAM(BOOL, `delete')
    PARAM(Window, `window')
    PARAM(Atom, `property')
    PARAM(Atom, `type')
    PARAM(CARD32, `long_offset')
    PARAM(CARD32, `long_length')
', `
    REPLY(CARD8, `format')
    REPLY(Atom, `type')
    REPLY(CARD32, `bytes_after')
    REPLY(CARD32, `value_len')
    PAD(12)
    ARRAYREPLY(BYTE, `value')
')

REQUEST(ListProperties, `
    OPCODE(21)
    PAD(1)
    PARAM(Window, `window')
', `
    PAD(1)
    REPLY(CARD16, `atoms_len')
    PAD(22)
    ARRAYREPLY(Atom, `atoms')
')

VOIDREQUEST(SetSelectionOwner, `
    OPCODE(22)
    PAD(1)
    PARAM(Window, `owner')
    PARAM(Atom, `selection')
    PARAM(Time, `time')
')

REQUEST(GetSelectionOwner, `
    OPCODE(23)
    PAD(1)
    PARAM(Atom, `selection')
')

VOIDREQUEST(ConvertSelection, `
    OPCODE(24)
    PAD(1)
    PARAM(Window, `requestor')
    PARAM(Atom, `selection')
    PARAM(Atom, `target')
    PARAM(Atom, `property')
    PARAM(Time, `time')
')

VOIDREQUEST(SendEvent, `
    OPCODE(25)
    PARAM(BOOL, `propagate')
    PARAM(Window, `destination')
    PARAM(CARD32, `event_mask')
    PARAM(xEvent, `event') dnl FIXME: Use of Xproto.h in XCB is deprecated.
')

REQUEST(GrabPointer, `
    OPCODE(26)
    PARAM(BOOL, `owner_events')
    PARAM(Window, `grab_window')
    PARAM(CARD16, `event_mask')
    PARAM(BYTE, `pointer_mode')
    PARAM(BYTE, `keyboard_mode')
    PARAM(Window, `confine_to')
    PARAM(Cursor, `cursor')
    PARAM(Time, `time')
')

VOIDREQUEST(UngrabPointer, `
    OPCODE(27)
    PAD(1)
    PARAM(Time, `time')
')

VOIDREQUEST(GrabButton, `
    OPCODE(28)
    PARAM(BOOL, `owner_events')
    PARAM(Window, `grab_window')
    PARAM(CARD16, `event_mask')
    PARAM(CARD8, `pointer_mode')
    PARAM(CARD8, `keyboard_mode')
    PARAM(Window, `confine_to')
    PARAM(Cursor, `cursor')
    PARAM(CARD8, `button')
    PAD(1)
    PARAM(CARD16, `modifiers')
')

VOIDREQUEST(UngrabButton, `
    OPCODE(29)
    PARAM(CARD8, `button')
    PARAM(Window, `grab_window')
    PARAM(CARD16, `modifiers')
    PAD(2)
')

VOIDREQUEST(ChangeActivePointerGrab, `
    OPCODE(30)
    PAD(1)
    PARAM(Cursor, `cursor')
    PARAM(Time, `time')
    PARAM(CARD16, `event_mask')
')

REQUEST(GrabKeyboard, `
    OPCODE(31)
    PARAM(BOOL, `owner_events')
    PARAM(Window, `grab_window')
    PARAM(Time, `time')
    PARAM(BYTE, `pointer_mode')
    PARAM(BYTE, `keyboard_mode')
')

VOIDREQUEST(UngrabKeyboard, `
    OPCODE(32)
    PAD(1)
    PARAM(Time, `time')
')

VOIDREQUEST(GrabKey, `
    OPCODE(33)
    PARAM(BOOL, `owner_events')
    PARAM(Window, `grab_window')
    PARAM(CARD16, `modifiers')
    PARAM(KeyCode, `key')
    PARAM(CARD8, `pointer_mode')
    PARAM(CARD8, `keyboard_mode')
')

VOIDREQUEST(UngrabKey, `
    OPCODE(34)
    PARAM(CARD8, `key')
    PARAM(Window, `grab_window')
    PARAM(CARD16, `modifiers')
')

VOIDREQUEST(AllowEvents, `
    OPCODE(35)
    PARAM(CARD8, `mode')
    PARAM(Time, `time')
')

VOIDREQUEST(GrabServer, `
    OPCODE(36)
')

VOIDREQUEST(UngrabServer, `
    OPCODE(37)
')

REQUEST(QueryPointer, `
    OPCODE(38)
    PAD(1)
    PARAM(Window, `window')
')

REQUEST(GetMotionEvents, `
    OPCODE(39)
    PAD(1)
    PARAM(Window, `window')
    PARAM(Time, `start')
    PARAM(Time, `stop')
', `
    ARRAYREPLY(xTimecoord, `events')
')

REQUEST(TranslateCoordinates, `
    OPCODE(40)
    PAD(1)
    PARAM(Window, `src_window')
    PARAM(Window, `dst_window')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
', `
    REPLY(BOOL, `same_screen')
    REPLY(Window, `child')
    REPLY(CARD16, `dst_x')
    REPLY(CARD16, `dst_y')
')

VOIDREQUEST(WarpPointer, `
    OPCODE(41)
    PAD(1)
    PARAM(Window, `src_window')
    PARAM(Window, `dst_window')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(CARD16, `src_width')
    PARAM(CARD16, `src_height')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
')

VOIDREQUEST(SetInputFocus, `
    OPCODE(42)
    PARAM(CARD8, `revert_to')
    PARAM(Window, `focus')
    PARAM(Time, `time')
')

REQUEST(GetInputFocus, `
    OPCODE(43)
')

REQUEST(QueryKeymap, `
    OPCODE(44)
')

VOIDREQUEST(OpenFont, `
    OPCODE(45)
    PAD(1)
    PARAM(Font, `fid')
    EXPRFIELD(CARD16, `name_len', `strlen(name)')
    LISTPARAM(char, `name', `name_len')
')

VOIDREQUEST(CloseFont, `
    OPCODE(46)
    PAD(1)
    PARAM(Font, `font')
')

REQUEST(QueryFont, `
    OPCODE(47)
    PAD(1)
    PARAM(Font, `font')
', `
    ARRAYREPLY(xFontProp, `properties', `nFontProps')
    ARRAYREPLY(xCharInfo, `char_infos')
')

REQUEST(QueryTextExtents, `
    OPCODE(48)
    EXPRFIELD(BOOL, `odd_length', `string_len & 1')
    PARAM(Font, `font')
    LOCALPARAM(CARD16, `string_len')
    LISTPARAM(CHAR2B, `string', `string_len')
')

dnl FIXME: ListFonts needs an iterator for the reply - a pointer won't do.
REQUEST(ListFonts, `
    OPCODE(49)
    PAD(1)
    PARAM(CARD16, `max_names')
    EXPRFIELD(CARD16, `pattern_len', `strlen(pattern)')
    LISTPARAM(char, `pattern', `pattern_len')
')

/* The ListFontsWithInfo request is not supported by XCB. */

VOIDREQUEST(SetFontPath, `
    OPCODE(51)
    PAD(1)
    PARAM(CARD16, `font_qty')
    LOCALPARAM(CARD16, `path_len')
    LISTPARAM(char, `path', `path_len')
')

dnl FIXME: GetFontPath needs an iterator for the reply - a pointer won't do.
REQUEST(GetFontPath, `
    OPCODE(52)
')

VOIDREQUEST(CreatePixmap, `
    OPCODE(53)
    PARAM(CARD8, `depth')
    PARAM(Pixmap, `pid')
    PARAM(Drawable, `drawable')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(FreePixmap, `
    OPCODE(54)
    PAD(1)
    PARAM(Pixmap, `pixmap')
')

VOIDREQUEST(CreateGC, `
    OPCODE(55)
    PAD(1)
    PARAM(GContext, `cid')
    PARAM(Drawable, `drawable')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(ChangeGC, `
    OPCODE(56)
    PAD(1)
    PARAM(GContext, `gc')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(CopyGC, `
    OPCODE(57)
    PAD(1)
    PARAM(GContext, `src_gc')
    PARAM(GContext, `dst_gc')
    PARAM(CARD32, `value_mask')
')

VOIDREQUEST(SetDashes, `
    OPCODE(58)
    PAD(1)
    PARAM(GContext, `gc')
    PARAM(CARD16, `dash_offset')
    PARAM(CARD16, `dashes_len')
    LISTPARAM(CARD8, `dashes', `dashes_len')
')

VOIDREQUEST(SetClipRectangles, `
    OPCODE(59)
    PARAM(BYTE, `ordering')
    PARAM(GContext, `gc')
    PARAM(INT16, `clip_x_origin')
    PARAM(INT16, `clip_y_origin')
    LOCALPARAM(CARD16, `rectangles_len')
    LISTPARAM(xRectangle, `rectangles', `rectangles_len')
')

VOIDREQUEST(FreeGC, `
    OPCODE(60)
    PAD(1)
    PARAM(GContext, `gc')
')

VOIDREQUEST(ClearArea, `
    OPCODE(61)
    PARAM(BOOL, `exposures')
    PARAM(Window, `window')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(CopyArea, `
    OPCODE(62)
    PAD(1)
    PARAM(Drawable, `src_drawable')
    PARAM(Drawable, `dst_drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(CopyPlane, `
    OPCODE(63)
    PAD(1)
    PARAM(Drawable, `src_drawable')
    PARAM(Drawable, `dst_drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `bit_plane')
')

VOIDREQUEST(PolyPoint, `
    OPCODE(64)
    PARAM(BYTE, `coordinate_mode')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(xPoint, `points', `points_len')
')

VOIDREQUEST(PolyLine, `
    OPCODE(65)
    PARAM(BYTE, `coordinate_mode')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(xPoint, `points', `points_len')
')

VOIDREQUEST(PolySegment, `
    OPCODE(66)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `segments_len')
    LISTPARAM(xSegment, `segments', `segments_len')
')

VOIDREQUEST(PolyRectangle, `
    OPCODE(67)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `rectangles_len')
    LISTPARAM(xRectangle, `rectangles', `rectangles_len')
')

VOIDREQUEST(PolyArc, `
    OPCODE(68)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `arcs_len')
    LISTPARAM(xArc, `arcs', `arcs_len')
')

VOIDREQUEST(FillPoly, `
    OPCODE(69)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(CARD8, `shape')
    PARAM(CARD8, `coordinate_mode')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(xPoint, `points', `points_len')
')

VOIDREQUEST(PolyFillRectangle, `
    OPCODE(70)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `rectangles_len')
    LISTPARAM(xRectangle, `rectangles', `rectangles_len')
')

VOIDREQUEST(PolyFillArc, `
    OPCODE(71)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `arcs_len')
    LISTPARAM(xArc, `arcs', `arcs_len')
')

VOIDREQUEST(PutImage, `
    OPCODE(72)
    PARAM(CARD8, `format')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD8, `left_pad')
    PARAM(CARD8, `depth')
    LOCALPARAM(CARD16, `data_len')
    LISTPARAM(BYTE, `data', `data_len')
')

REQUEST(GetImage, `
    OPCODE(73)
    PARAM(CARD8, `format')
    PARAM(Drawable, `drawable')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `plane_mask')
', `ARRAYREPLY(BYTE, `data')')

VOIDREQUEST(PolyText8, `
    OPCODE(74)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `items_len')
    LISTPARAM(BYTE, `items', `items_len')
')

VOIDREQUEST(PolyText16, `
    OPCODE(75)
    PAD(1)
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `items_len')
    LISTPARAM(BYTE, `items', `items_len')
')

VOIDREQUEST(ImageText8, `
    OPCODE(76)
    EXPRFIELD(BYTE, `string_len', `strlen(string)')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LISTPARAM(char, `string', `string_len')
')

VOIDREQUEST(ImageText16, `
    OPCODE(77)
    PARAM(BYTE, `string_len')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LISTPARAM(CHAR2B, `string', `string_len')
')

VOIDREQUEST(CreateColormap, `
    OPCODE(78)
    PARAM(BYTE, `alloc')
    PARAM(Colormap, `mid')
    PARAM(Window, `window')
    PARAM(VisualID, `visual')
')

VOIDREQUEST(FreeColormap, `
    OPCODE(79)
    PAD(1)
    PARAM(Colormap, `cmap')
')

VOIDREQUEST(CopyColormapAndFree, `
    OPCODE(80)
    PAD(1)
    PARAM(Colormap, `mid')
    PARAM(Colormap, `src_cmap')
')

VOIDREQUEST(InstallColormap, `
    OPCODE(81)
    PAD(1)
    PARAM(Colormap, `cmap')
')

VOIDREQUEST(UninstallColormap, `
    OPCODE(82)
    PAD(1)
    PARAM(Colormap, `cmap')
')

REQUEST(ListInstalledColormaps, `
    OPCODE(83)
    PAD(1)
    PARAM(Window, `window')
', `
    ARRAYREPLY(Colormap, `cmaps', `nColormaps')
')

REQUEST(AllocColor, `
    OPCODE(84)
    PAD(1)
    PARAM(Colormap, `cmap')
    PARAM(CARD16, `red')
    PARAM(CARD16, `green')
    PARAM(CARD16, `blue')
')

REQUEST(AllocNamedColor, `
    OPCODE(85)
    PAD(1)
    PARAM(Colormap, `cmap')
    EXPRFIELD(CARD16, `name_len', `strlen(name)')
    LISTPARAM(char, `name', `name_len')
')

REQUEST(AllocColorCells, `
    OPCODE(86)
    PARAM(BOOL, `contiguous')
    PARAM(Colormap, `cmap')
    PARAM(CARD16, `colors')
    PARAM(CARD16, `planes')
', `
    ARRAYREPLY(CARD32, `pixels', `nPixels')
    ARRAYREPLY(CARD32, `masks', `nMasks')
')

REQUEST(AllocColorPlanes, `
    OPCODE(87)
    PARAM(BOOL, `contiguous')
    PARAM(Colormap, `cmap')
    PARAM(CARD16, `colors')
    PARAM(CARD16, `reds')
    PARAM(CARD16, `greens')
    PARAM(CARD16, `blues')
', `
    ARRAYREPLY(CARD32, `pixels', `nPixels')
')

VOIDREQUEST(FreeColors, `
    OPCODE(88)
    PAD(1)
    PARAM(Colormap, `cmap')
    VALUEPARAM(CARD32, `plane_mask', `pixels')
')
    
VOIDREQUEST(StoreColors, `
    OPCODE(89)
    PAD(1)
    PARAM(Colormap, `cmap')
    LOCALPARAM(CARD16, `items_len')
    LISTPARAM(xColorItem, `items', `items_len')
')

VOIDREQUEST(StoreNamedColor, `
    OPCODE(90)
    PARAM(CARD8, `flags')
    PARAM(Colormap, `cmap')
    PARAM(CARD32, `pixel')
    EXPRFIELD(CARD16, `name_len', `strlen(name)')
    LISTPARAM(char, `name', `name_len')
')

REQUEST(QueryColors, `
    OPCODE(91)
    PAD(1)
    PARAM(Colormap, `cmap')
    LOCALPARAM(CARD16, `pixels_len')
    LISTPARAM(CARD32, `pixels', `pixels_len')
')

REQUEST(LookupColor, `
    OPCODE(92)
    PAD(1)
    PARAM(Colormap, `cmap')
    EXPRFIELD(CARD16, `name_len', `strlen(name)')
    LISTPARAM(char, `name', `name_len')
')

VOIDREQUEST(CreateCursor, `
    OPCODE(93)
    PAD(1)
    PARAM(Cursor, `cid')
    PARAM(Pixmap, `source')
    PARAM(Pixmap, `mask')
    PARAM(CARD16, `fore_red')
    PARAM(CARD16, `fore_green')
    PARAM(CARD16, `fore_blue')
    PARAM(CARD16, `back_red')
    PARAM(CARD16, `back_green')
    PARAM(CARD16, `back_blue')
    PARAM(CARD16, `x')
    PARAM(CARD16, `y')
')

VOIDREQUEST(CreateGlyphCursor, `
    OPCODE(94)
    PAD(1)
    PARAM(Cursor, `cid')
    PARAM(Font, `source_font')
    PARAM(Font, `mask_font')
    PARAM(CARD16, `source_char')
    PARAM(CARD16, `mask_char')
    PARAM(CARD16, `fore_red')
    PARAM(CARD16, `fore_green')
    PARAM(CARD16, `fore_blue')
    PARAM(CARD16, `back_red')
    PARAM(CARD16, `back_green')
    PARAM(CARD16, `back_blue')
')

VOIDREQUEST(FreeCursor, `
    OPCODE(95)
    PAD(1)
    PARAM(Cursor, `cursor')
')

VOIDREQUEST(RecolorCursor, `
    OPCODE(96)
    PAD(1)
    PARAM(Cursor, `cursor')
    PARAM(CARD16, `fore_red')
    PARAM(CARD16, `fore_green')
    PARAM(CARD16, `fore_blue')
    PARAM(CARD16, `back_red')
    PARAM(CARD16, `back_green')
    PARAM(CARD16, `back_blue')
')

REQUEST(QueryBestSize, `
    OPCODE(97)
    PARAM(CARD8, `class')
    PARAM(Drawable, `drawable')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

REQUEST(QueryExtension, `
    OPCODE(98)
    PAD(1)
    EXPRFIELD(CARD16, `name_len', `strlen(name)')
    LISTPARAM(char, `name', `name_len')
', `
    PAD(1)
    REPLY(BOOL, `present')
    REPLY(CARD8, `major_opcode')
    REPLY(CARD8, `first_event')
    REPLY(CARD8, `first_error')
')

dnl FIXME: ListExtensions needs an iterator for the reply - a pointer won't do.
REQUEST(ListExtensions, `
    OPCODE(99)
')

VOIDREQUEST(ChangeKeyboardMapping, `
    OPCODE(100)
    PARAM(CARD8, `keycode_count')
    PARAM(KeyCode, `first_keycode')
    PARAM(CARD8, `keysyms_per_keycode')
    LISTPARAM(KeySym, `keysyms', `keycode_count * keysyms_per_keycode')
')

REQUEST(GetKeyboardMapping, `
    OPCODE(101)
    PAD(1)
    PARAM(KeyCode, `first_keycode')
    PARAM(CARD8, `count')
')

VOIDREQUEST(ChangeKeyboardControl, `
    OPCODE(102)
    PAD(1)
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

REQUEST(GetKeyboardControl, `
    OPCODE(103)
')

VOIDREQUEST(Bell, `
    OPCODE(104)
    PARAM(INT8, `percent')
')

VOIDREQUEST(ChangePointerControl, `
    OPCODE(105)
    PAD(1)
    PARAM(INT16, `acceleration_numerator')
    PARAM(INT16, `acceleration_denominator')
    PARAM(INT16, `threshold')
    PARAM(BOOL, `do_acceleration')
    PARAM(BOOL, `do_threshold')
')

REQUEST(GetPointerControl, `
    OPCODE(106)
')

VOIDREQUEST(SetScreenSaver, `
    OPCODE(107)
    PAD(1)
    PARAM(INT16, `timeout')
    PARAM(INT16, `interval')
    PARAM(CARD8, `prefer_blanking')
    PARAM(CARD8, `allow_exposures')
')

REQUEST(GetScreenSaver, `
    OPCODE(108)
')

VOIDREQUEST(ChangeHosts, `
    OPCODE(109)
    PARAM(CARD8, `mode')
    PARAM(CARD8, `family')
    PAD(1)
    EXPRFIELD(CARD16, `address_len', `strlen(address)')
    LISTPARAM(char, `address', `address_len')
')

REQUEST(ListHosts, `
    OPCODE(110)
')

VOIDREQUEST(SetAccessControl, `
    OPCODE(111)
    PARAM(CARD8, `mode')
')

VOIDREQUEST(SetCloseDownMode, `
    OPCODE(112)
    PARAM(CARD8, `mode')
')

VOIDREQUEST(KillClient, `
    OPCODE(113)
    PAD(1)
    PARAM(CARD32, `resource')
')

VOIDREQUEST(RotateProperties, `
    OPCODE(114)
    PARAM(Window, `window')
    PARAM(CARD16, `nAtoms')
    PARAM(INT16, `nPositions')
    LISTPARAM(Atom, `atoms', `nAtoms')
')

VOIDREQUEST(ForceScreenSaver, `
    OPCODE(115)
    PARAM(CARD8, `mode')
')

REQUEST(SetPointerMapping, `
    OPCODE(116)
    PARAM(CARD8, `map_len')
    LISTPARAM(CARD8, `map', `map_len')
')

REQUEST(GetPointerMapping, `
    OPCODE(117)
')

REQUEST(SetModifierMapping, `
    OPCODE(118)
    PARAM(CARD8, `keycodes_per_modifier')
    LISTPARAM(KeyCode, `keycodes', `8 * keycodes_per_modifier')
')

REQUEST(GetModifierMapping, `
    OPCODE(119)
')

dnl FIXME: NoOperation should allow specifying payload length
dnl but geez, malloc()ing a 262140 byte buffer just so I have something
dnl to hand to write(2) seems silly...!
VOIDREQUEST(NoOperation, `
    OPCODE(127)
')


/* Pseudo-requests: these functions don't map directly to protocol requests,
 * but depend on requests in the core protocol, so they're here. */

/* Returns true iff the sync was sucessful. */
FUNCTION(`int XCB_Sync', `XCB_Connection *c, XCB_Event **e', `
    XCB_GetInputFocus_cookie cookie = XCB_GetInputFocus(c);
    XCB_GetInputFocus_Rep *reply = XCB_GetInputFocus_Reply(c, cookie, e);
    free(reply);
    return (reply != 0);
')

STATICSTRUCT(XCB_ExtensionRecord, `
    POINTERFIELD(char, `name')
    POINTERFIELD(XCB_QueryExtension_Rep, `info')
')
_C
STATICFUNCTION(`int match_extension_string', `const void *name, const void *data', `
    return (((XCB_ExtensionRecord *) data)->name == name);
')
_C
/* Do not free the returned XCB_QueryExtension_Rep - on return, it's aliased
 * from the cache. */
FUNCTION(`const XCB_QueryExtension_Rep *XCB_QueryExtension_Cached',
`XCB_Connection *c, const char *name, XCB_Event **e', `
    XCB_ExtensionRecord *data = 0;
    if(e)
        *e = 0;
    pthread_mutex_lock(&c->locked);

    data = (XCB_ExtensionRecord *) XCB_List_remove(&c->extension_cache, match_extension_string, name);

    if(data)
        goto done; /* cache hit: return from the cache */

    /* cache miss: query the server */
ALLOC(XCB_ExtensionRecord, `data', 1)
    data->name = (char *) name;
    pthread_mutex_unlock(&c->locked);
    {
        XCB_QueryExtension_cookie cookie = XCB_QueryExtension(c, name);
        data->info = XCB_QueryExtension_Reply(c, cookie, e);
    }
    pthread_mutex_lock(&c->locked);

done:
    XCB_List_insert(&c->extension_cache, data);

    pthread_mutex_unlock(&c->locked);
    return data->info;
')
ENDXCBGEN
