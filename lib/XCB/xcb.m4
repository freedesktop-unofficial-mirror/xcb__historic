XCBGEN(xcb, `
Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')
SOURCEONLY(`
REQUIRE(stdlib)
REQUIRE(stdio)
REQUIRE(string)
')HEADERONLY(`
REQUIRE(X11, XCB, xcb_conn)

/* Core event and error types */

EVENT(KeyPress, 2, `
    REPLY(KEYCODE, `detail')
    REPLY(TIMESTAMP, `time')
    REPLY(WINDOW, `root')
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `child')
    REPLY(INT16, `root_x')
    REPLY(INT16, `root_y')
    REPLY(INT16, `event_x')
    REPLY(INT16, `event_y')
    REPLY(CARD16, `state')
    REPLY(BOOL, `same_screen')
')
EVENTCOPY(KeyRelease, 3, KeyPress)
EVENT(ButtonPress, 4, `
    REPLY(BUTTON, `detail')
    REPLY(TIMESTAMP, `time')
    REPLY(WINDOW, `root')
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `child')
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
    REPLY(TIMESTAMP, `time')
    REPLY(WINDOW, `root')
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `child')
    REPLY(INT16, `root_x')
    REPLY(INT16, `root_y')
    REPLY(INT16, `event_x')
    REPLY(INT16, `event_y')
    REPLY(CARD16, `state')
    REPLY(BOOL, `same_screen')
')
EVENT(EnterNotify, 7, `
    REPLY(BYTE, `detail')
    REPLY(TIMESTAMP, `time')
    REPLY(WINDOW, `root')
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `child')
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
    REPLY(WINDOW, `event')
    REPLY(BYTE, `mode')
')
EVENTCOPY(FocusOut, 10, FocusIn)
EVENT(KeymapNotify, 11, `
    define(`FIELDQTY', 0) dnl cancel usual output of seqnum field
    REPLY(CARD8, `keys[31]')
')
EVENT(Expose, 12, `
    PAD(1)
    REPLY(WINDOW, `window')
    REPLY(CARD16, `x')
    REPLY(CARD16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `count')
')
EVENT(GraphicsExposure, 13, `
    PAD(1)
    REPLY(DRAWABLE, `drawable')
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
    REPLY(DRAWABLE, `drawable')
    REPLY(CARD16, `minor_opcode')
    REPLY(CARD8, `major_opcode')
')
EVENT(VisibilityNotify, 15, `
    PAD(1)
    REPLY(WINDOW, `window')
    REPLY(BYTE, `state')
')
EVENT(CreateNotify, 16, `
    PAD(1)
    REPLY(WINDOW, `parent')
    REPLY(WINDOW, `window')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
    REPLY(BOOL, `override_redirect')
')
EVENT(DestroyNotify, 17, `
    PAD(1)
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `window')
')
EVENT(UnmapNotify, 18, `
    PAD(1)
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `window')
    REPLY(BOOL, `from_configure')
')
EVENT(MapNotify, 19, `
    PAD(1)
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `window')
    REPLY(BOOL, `override_redirect')
')
EVENT(MapRequest, 20, `
    PAD(1)
    REPLY(WINDOW, `parent')
    REPLY(WINDOW, `window')
')
EVENT(ReparentNotify, 21, `
    PAD(1)
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `window')
    REPLY(WINDOW, `parent')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(BOOL, `override_redirect')
')
EVENT(ConfigureNotify, 22, `
    PAD(1)
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `window')
    REPLY(WINDOW, `above_sibling')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
    REPLY(BOOL, `override_redirect')
')
EVENT(ConfigureRequest, 23, `
    REPLY(BYTE, `stack_mode')
    REPLY(WINDOW, `parent')
    REPLY(WINDOW, `window')
    REPLY(WINDOW, `sibling')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
    REPLY(CARD16, `value_mask')
')
EVENT(GravityNotify, 24, `
    PAD(1)
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `window')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
')
EVENT(ResizeRequest, 25, `
    PAD(1)
    REPLY(WINDOW, `window')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
')
EVENT(CirculateNotify, 26, `
    PAD(1)
    REPLY(WINDOW, `event')
    REPLY(WINDOW, `window')
    PAD(4)
    REPLY(BYTE, `place')
')
EVENTCOPY(CirculateRequest, 27, CirculateNotify)
EVENT(PropertyNotify, 28, `
    PAD(1)
    REPLY(WINDOW, `window')
    REPLY(ATOM, `atom')
    REPLY(TIMESTAMP, `time')
    REPLY(BYTE, `state')
')
EVENT(SelectionClear, 29, `
    PAD(1)
    REPLY(TIMESTAMP, `time')
    REPLY(WINDOW, `owner')
    REPLY(ATOM, `selection')
')
EVENT(SelectionRequest, 30, `
    PAD(1)
    REPLY(TIMESTAMP, `time')
    REPLY(WINDOW, `owner')
    REPLY(WINDOW, `requestor')
    REPLY(ATOM, `selection')
    REPLY(ATOM, `target')
    REPLY(ATOM, `property')
')
EVENT(SelectionNotify, 31, `
    PAD(1)
    REPLY(TIMESTAMP, `time')
    REPLY(WINDOW, `requestor')
    REPLY(ATOM, `selection')
    REPLY(ATOM, `target')
    REPLY(ATOM, `property')
')
EVENT(ColormapNotify, 32, `
    PAD(1)
    REPLY(WINDOW, `window')
    REPLY(COLORMAP, `colormap')
    REPLY(BOOL, `_new')
    REPLY(BYTE, `state')
')
EVENT(ClientMessage, 33, `
    REPLY(CARD8, `format')
    REPLY(WINDOW, `window')
    REPLY(ATOM, `type')
')
EVENT(MappingNotify, 34, `
    PAD(1)
    REPLY(BYTE, `request')
    REPLY(KEYCODE, `first_keycode')
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
/* It is the caller's responsibility to free returned XCB*Rep objects. */

/* The ListFontsWithInfo request is not supported by XCB. */

PUSHDIV(-1)

dnl Window attributes for CreateWindow and ChangeWindowAttributes.
XCBENUM(CW,
BackPixmap = 1L<<0,
BackPixel = 1L<<1,
BorderPixmap = 1L<<2,
BorderPixel = 1L<<3,
BitGravity = 1L<<4,
WinGravity = 1L<<5,
BackingStore = 1L<<6,
BackingPlanes = 1L<<7,
BackingPixel = 1L<<8,
OverrideRedirect = 1L<<9,
SaveUnder = 1L<<10,
EventMask = 1L<<11,
DontPropagate = 1L<<12,
Colormap = 1L<<13,
Cursor = 1L<<14,
)

VOIDREQUEST(CreateWindow, `
    OPCODE(1)
    PARAM(CARD8, `depth')
    PARAM(WINDOW, `wid')
    PARAM(WINDOW, `parent')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD16, `border_width')
    PARAM(CARD16, `class')
    PARAM(VISUALID, `visual')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(ChangeWindowAttributes, `
    OPCODE(2)
    PAD(1)
    PARAM(WINDOW, `window')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

REQUEST(GetWindowAttributes, `
    OPCODE(3)
    PAD(1)
    PARAM(WINDOW, `window')
', `
    REPLY(CARD8, `backing_store')
    REPLY(VISUALID, `visual')
    REPLY(CARD16, `_class')
    REPLY(CARD8, `bit_gravity')
    REPLY(CARD8, `win_gravity')
    REPLY(CARD32, `backing_planes')
    REPLY(CARD32, `backing_pixel')
    REPLY(BOOL, `save_under')
    REPLY(BOOL, `map_is_installed')
    REPLY(CARD8, `map_state')
    REPLY(BOOL, `override_redirect')
    REPLY(COLORMAP, `colormap')
    REPLY(CARD32, `all_event_masks')
    REPLY(CARD32, `your_event_mask')
    REPLY(CARD16, `do_not_propagate_mask')
')

VOIDREQUEST(DestroyWindow, `
    OPCODE(4)
    PAD(1)
    PARAM(WINDOW, `window')
')

VOIDREQUEST(DestroySubwindows, `
    OPCODE(5)
    PAD(1)
    PARAM(WINDOW, `window')
')

VOIDREQUEST(ChangeSaveSet, `
    OPCODE(6)
    PARAM(BYTE, `mode')
    PARAM(WINDOW, `window')
')

VOIDREQUEST(ReparentWindow, `
    OPCODE(7)
    PAD(1)
    PARAM(WINDOW, `window')
    PARAM(WINDOW, `parent')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
')

VOIDREQUEST(MapWindow, `
    OPCODE(8)
    PAD(1)
    PARAM(WINDOW, `window')
')

VOIDREQUEST(MapSubwindows, `
    OPCODE(9)
    PAD(1)
    PARAM(WINDOW, `window')
')

VOIDREQUEST(UnmapWindow, `
    OPCODE(10)
    PAD(1)
    PARAM(WINDOW, `window')
')

VOIDREQUEST(UnmapSubwindows, `
    OPCODE(11)
    PAD(1)
    PARAM(WINDOW, `window')
')

VOIDREQUEST(ConfigureWindow, `
    OPCODE(12)
    PAD(1)
    PARAM(WINDOW, `window')
    VALUEPARAM(CARD16, `value_mask', `value_list')
')

VOIDREQUEST(CirculateWindow, `
    OPCODE(13)
    PARAM(CARD8, `direction')
    PARAM(WINDOW, `window')
')

REQUEST(GetGeometry, `
    OPCODE(14)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
', `
    REPLY(CARD8, `depth')
    REPLY(WINDOW, `root')
    REPLY(INT16, `x')
    REPLY(INT16, `y')
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
    REPLY(CARD16, `border_width')
')

REQUEST(QueryTree, `
    OPCODE(15)
    PAD(1)
    PARAM(WINDOW, `window')
', `
    PAD(1)
    REPLY(WINDOW, `root')
    REPLY(WINDOW, `parent')
    REPLY(CARD16, `children_len')
    PAD(14)
    ARRAYREPLY(WINDOW, `children', `R->children_len')
')

REQUEST(InternAtom, `
    OPCODE(16)
    PARAM(BOOL, `only_if_exists')
    PARAM(CARD16, `name_len')
    PAD(2)
    LISTPARAM(char, `name', `name_len')
', `
    PAD(1)
    REPLY(ATOM, `atom')
')

REQUEST(GetAtomName, `
    OPCODE(17)
    PAD(1)
    PARAM(ATOM, `atom')
', `
    PAD(1)
    REPLY(CARD16, `name_len')
    PAD(22)
    ARRAYREPLY(CARD8, `name', `R->name_len')
')

VOIDREQUEST(ChangeProperty, `
    OPCODE(18)
    PARAM(CARD8, `mode')
    PARAM(WINDOW, `window')
    PARAM(ATOM, `property')
    PARAM(ATOM, `type')
    PARAM(CARD8, `format')
    PAD(3)
    PARAM(CARD32, `data_len')
    LISTPARAM(void, `data', `data_len * format / 8')
')

VOIDREQUEST(DeleteProperty, `
    OPCODE(19)
    PAD(1)
    PARAM(WINDOW, `window')
    PARAM(ATOM, `property')
')

REQUEST(GetProperty, `
    OPCODE(20)
    PARAM(BOOL, `delete')
    PARAM(WINDOW, `window')
    PARAM(ATOM, `property')
    PARAM(ATOM, `type')
    PARAM(CARD32, `long_offset')
    PARAM(CARD32, `long_length')
', `
    REPLY(CARD8, `format')
    REPLY(ATOM, `type')
    REPLY(CARD32, `bytes_after')
    REPLY(CARD32, `value_len')
    PAD(12)
    ARRAYREPLY(void, `value', `R->value_len * 8 / R->format')
')

REQUEST(ListProperties, `
    OPCODE(21)
    PAD(1)
    PARAM(WINDOW, `window')
', `
    PAD(1)
    REPLY(CARD16, `atoms_len')
    PAD(22)
    ARRAYREPLY(ATOM, `atoms', `R->atoms_len')
')

VOIDREQUEST(SetSelectionOwner, `
    OPCODE(22)
    PAD(1)
    PARAM(WINDOW, `owner')
    PARAM(ATOM, `selection')
    PARAM(TIMESTAMP, `time')
')

REQUEST(GetSelectionOwner, `
    OPCODE(23)
    PAD(1)
    PARAM(ATOM, `selection')
', `
    PAD(1)
    REPLY(WINDOW, `owner')
')

VOIDREQUEST(ConvertSelection, `
    OPCODE(24)
    PAD(1)
    PARAM(WINDOW, `requestor')
    PARAM(ATOM, `selection')
    PARAM(ATOM, `target')
    PARAM(ATOM, `property')
    PARAM(TIMESTAMP, `time')
')

VOIDREQUEST(SendEvent, `
    OPCODE(25)
    PARAM(BOOL, `propagate')
    PARAM(WINDOW, `destination')
    PARAM(CARD32, `event_mask')
    LISTPARAM(char, `event', `32')
')

REQUEST(GrabPointer, `
    OPCODE(26)
    PARAM(BOOL, `owner_events')
    PARAM(WINDOW, `grab_window')
    PARAM(CARD16, `event_mask')
    PARAM(BYTE, `pointer_mode')
    PARAM(BYTE, `keyboard_mode')
    PARAM(WINDOW, `confine_to')
    PARAM(CURSOR, `cursor')
    PARAM(TIMESTAMP, `time')
', `
    REPLY(BYTE, `status')
')

VOIDREQUEST(UngrabPointer, `
    OPCODE(27)
    PAD(1)
    PARAM(TIMESTAMP, `time')
')

VOIDREQUEST(GrabButton, `
    OPCODE(28)
    PARAM(BOOL, `owner_events')
    PARAM(WINDOW, `grab_window')
    PARAM(CARD16, `event_mask')
    PARAM(CARD8, `pointer_mode')
    PARAM(CARD8, `keyboard_mode')
    PARAM(WINDOW, `confine_to')
    PARAM(CURSOR, `cursor')
    PARAM(CARD8, `button')
    PAD(1)
    PARAM(CARD16, `modifiers')
')

VOIDREQUEST(UngrabButton, `
    OPCODE(29)
    PARAM(CARD8, `button')
    PARAM(WINDOW, `grab_window')
    PARAM(CARD16, `modifiers')
    PAD(2)
')

VOIDREQUEST(ChangeActivePointerGrab, `
    OPCODE(30)
    PAD(1)
    PARAM(CURSOR, `cursor')
    PARAM(TIMESTAMP, `time')
    PARAM(CARD16, `event_mask')
')

REQUEST(GrabKeyboard, `
    OPCODE(31)
    PARAM(BOOL, `owner_events')
    PARAM(WINDOW, `grab_window')
    PARAM(TIMESTAMP, `time')
    PARAM(BYTE, `pointer_mode')
    PARAM(BYTE, `keyboard_mode')
', `
    REPLY(BYTE, `status')
')

VOIDREQUEST(UngrabKeyboard, `
    OPCODE(32)
    PAD(1)
    PARAM(TIMESTAMP, `time')
')

VOIDREQUEST(GrabKey, `
    OPCODE(33)
    PARAM(BOOL, `owner_events')
    PARAM(WINDOW, `grab_window')
    PARAM(CARD16, `modifiers')
    PARAM(KEYCODE, `key')
    PARAM(CARD8, `pointer_mode')
    PARAM(CARD8, `keyboard_mode')
')

VOIDREQUEST(UngrabKey, `
    OPCODE(34)
    PARAM(CARD8, `key')
    PARAM(WINDOW, `grab_window')
    PARAM(CARD16, `modifiers')
')

VOIDREQUEST(AllowEvents, `
    OPCODE(35)
    PARAM(CARD8, `mode')
    PARAM(TIMESTAMP, `time')
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
    PARAM(WINDOW, `window')
', `
    REPLY(BOOL, `same_screen')
    REPLY(WINDOW, `root')
    REPLY(WINDOW, `child')
    REPLY(INT16, `root_x')
    REPLY(INT16, `root_y')
    REPLY(INT16, `win_x')
    REPLY(INT16, `win_y')
    REPLY(CARD16, `mask')
')

STRUCT(TIMECOORD, `
    FIELD(TIMESTAMP, `time')
    FIELD(INT16, `x')
    FIELD(INT16, `y')
')

REQUEST(GetMotionEvents, `
    OPCODE(39)
    PAD(1)
    PARAM(WINDOW, `window')
    PARAM(TIMESTAMP, `start')
    PARAM(TIMESTAMP, `stop')
', `
    PAD(1)
    REPLY(CARD32, `events_len')
    PAD(20)
    ARRAYREPLY(TIMECOORD, `events', `R->events_len')
')

REQUEST(TranslateCoordinates, `
    OPCODE(40)
    PAD(1)
    PARAM(WINDOW, `src_window')
    PARAM(WINDOW, `dst_window')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
', `
    REPLY(BOOL, `same_screen')
    REPLY(WINDOW, `child')
    REPLY(CARD16, `dst_x')
    REPLY(CARD16, `dst_y')
')

VOIDREQUEST(WarpPointer, `
    OPCODE(41)
    PAD(1)
    PARAM(WINDOW, `src_window')
    PARAM(WINDOW, `dst_window')
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
    PARAM(WINDOW, `focus')
    PARAM(TIMESTAMP, `time')
')

REQUEST(GetInputFocus, `
    OPCODE(43)
', `
    REPLY(CARD8, `revert_to')
    REPLY(WINDOW, `focus')
')

REQUEST(QueryKeymap, `
    OPCODE(44)
', `
    PAD(1)
    REPLY(CARD8, `keys[32]')
')

VOIDREQUEST(OpenFont, `
    OPCODE(45)
    PAD(1)
    PARAM(FONT, `fid')
    PARAM(CARD16, `name_len')
    LISTPARAM(char, `name', `name_len')
')

VOIDREQUEST(CloseFont, `
    OPCODE(46)
    PAD(1)
    PARAM(FONT, `font')
')

STRUCT(FONTPROP, `
    FIELD(ATOM, `name')
    FIELD(CARD32, `value')
')

STRUCT(CHARINFO, `
    FIELD(INT16, `left_side_bearing')
    FIELD(INT16, `right_side_bearing')
    FIELD(INT16, `character_width')
    FIELD(INT16, `ascent')
    FIELD(INT16, `descent')
    FIELD(CARD16, `attributes')
')

REQUEST(QueryFont, `
    OPCODE(47)
    PAD(1)
    PARAM(FONTABLE, `font')
', `
    PAD(1)
    REPLY(CHARINFO, `min_bounds')
    PAD(4)
    REPLY(CHARINFO, `max_bounds')
    PAD(4)
    REPLY(CARD16, `min_char_or_byte2')
    REPLY(CARD16, `max_char_or_byte2')
    REPLY(CARD16, `default_char')
    REPLY(CARD16, `properties_len')
    REPLY(BYTE, `draw_direction')
    REPLY(CARD8, `min_byte1')
    REPLY(CARD8, `max_byte1')
    REPLY(BOOL, `all_chars_exist')
    REPLY(INT16, `font_ascent')
    REPLY(INT16, `font_descent')
    REPLY(CARD32, `char_infos_len')
    ARRAYREPLY(FONTPROP, `properties', `R->properties_len')
    ARRAYREPLY(CHARINFO, `char_infos', `R->char_infos_len')
')

REQUEST(QueryTextExtents, `
    OPCODE(48)
    EXPRFIELD(BOOL, `odd_length', `string_len & 1')
    PARAM(FONTABLE, `font')
    LOCALPARAM(CARD16, `string_len')
    LISTPARAM(CHAR2B, `string', `string_len')
', `
    REPLY(BYTE, `draw_direction')
    REPLY(INT16, `font_ascent')
    REPLY(INT16, `font_descent')
    REPLY(INT16, `overall_ascent')
    REPLY(INT16, `overall_descent')
    REPLY(INT32, `overall_width')
    REPLY(INT32, `overall_left')
    REPLY(INT32, `overall_right')
')

STRUCT(STR, `
    FIELD(CARD8, `name_len')
    ARRAYFIELD(char, `name', `R->name_len')
')

REQUEST(ListFonts, `
    OPCODE(49)
    PAD(1)
    PARAM(CARD16, `max_names')
    PARAM(CARD16, `pattern_len')
    LISTPARAM(char, `pattern', `pattern_len')
', `
    PAD(1)
    REPLY(CARD16, `names_len')
    PAD(22)
    LISTFIELD(STR, `names', `R->names_len')
')

VOIDREQUEST(SetFontPath, `
    OPCODE(51)
    PAD(1)
    PARAM(CARD16, `font_qty')
    LOCALPARAM(CARD16, `path_len')
    LISTPARAM(char, `path', `path_len')
')

REQUEST(GetFontPath, `
    OPCODE(52)
', `
    PAD(1)
    REPLY(CARD16, `path_len')
    PAD(22)
    LISTFIELD(STR, `path', `R->path_len')
')

VOIDREQUEST(CreatePixmap, `
    OPCODE(53)
    PARAM(CARD8, `depth')
    PARAM(PIXMAP, `pid')
    PARAM(DRAWABLE, `drawable')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(FreePixmap, `
    OPCODE(54)
    PAD(1)
    PARAM(PIXMAP, `pixmap')
')

VOIDREQUEST(CreateGC, `
    OPCODE(55)
    PAD(1)
    PARAM(GCONTEXT, `cid')
    PARAM(DRAWABLE, `drawable')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(ChangeGC, `
    OPCODE(56)
    PAD(1)
    PARAM(GCONTEXT, `gc')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(CopyGC, `
    OPCODE(57)
    PAD(1)
    PARAM(GCONTEXT, `src_gc')
    PARAM(GCONTEXT, `dst_gc')
    PARAM(CARD32, `value_mask')
')

VOIDREQUEST(SetDashes, `
    OPCODE(58)
    PAD(1)
    PARAM(GCONTEXT, `gc')
    PARAM(CARD16, `dash_offset')
    PARAM(CARD16, `dashes_len')
    LISTPARAM(CARD8, `dashes', `dashes_len')
')

VOIDREQUEST(SetClipRectangles, `
    OPCODE(59)
    PARAM(BYTE, `ordering')
    PARAM(GCONTEXT, `gc')
    PARAM(INT16, `clip_x_origin')
    PARAM(INT16, `clip_y_origin')
    LOCALPARAM(CARD16, `rectangles_len')
    LISTPARAM(RECTANGLE, `rectangles', `rectangles_len')
')

VOIDREQUEST(FreeGC, `
    OPCODE(60)
    PAD(1)
    PARAM(GCONTEXT, `gc')
')

VOIDREQUEST(ClearArea, `
    OPCODE(61)
    PARAM(BOOL, `exposures')
    PARAM(WINDOW, `window')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(CopyArea, `
    OPCODE(62)
    PAD(1)
    PARAM(DRAWABLE, `src_drawable')
    PARAM(DRAWABLE, `dst_drawable')
    PARAM(GCONTEXT, `gc')
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
    PARAM(DRAWABLE, `src_drawable')
    PARAM(DRAWABLE, `dst_drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `bit_plane')
')

VOIDREQUEST(PolyPoint, `
    MARSHAL(drawable.window.xid, gc.xid, coordinate_mode)
    OPCODE(64)
    PARAM(BYTE, `coordinate_mode')
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(POINT, `points', `points_len')
')

VOIDREQUEST(PolyLine, `
    MARSHAL(drawable.window.xid, gc.xid, coordinate_mode)
    OPCODE(65)
    PARAM(BYTE, `coordinate_mode')
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(POINT, `points', `points_len')
')

STRUCT(SEGMENT, `
    FIELD(INT16, `x1')
    FIELD(INT16, `y1')
    FIELD(INT16, `x2')
    FIELD(INT16, `y2')
')

VOIDREQUEST(PolySegment, `
    MARSHAL(drawable.window.xid, gc.xid)
    OPCODE(66)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    LOCALPARAM(CARD16, `segments_len')
    LISTPARAM(SEGMENT, `segments', `segments_len')
')

VOIDREQUEST(PolyRectangle, `
    MARSHAL(drawable.window.xid, gc.xid)
    OPCODE(67)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    LOCALPARAM(CARD16, `rectangles_len')
    LISTPARAM(RECTANGLE, `rectangles', `rectangles_len')
')

dnl The semantics of PolyArc change after the first arc: the GC's
dnl join style may be applied to successive arcs under some circumstances.
dnl So marshaling here is bad.
VOIDREQUEST(PolyArc, `
    OPCODE(68)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    LOCALPARAM(CARD16, `arcs_len')
    LISTPARAM(ARC, `arcs', `arcs_len')
')

VOIDREQUEST(FillPoly, `
    OPCODE(69)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(CARD8, `shape')
    PARAM(CARD8, `coordinate_mode')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(POINT, `points', `points_len')
')

VOIDREQUEST(PolyFillRectangle, `
    MARSHAL(drawable.window.xid, gc.xid)
    OPCODE(70)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    LOCALPARAM(CARD16, `rectangles_len')
    LISTPARAM(RECTANGLE, `rectangles', `rectangles_len')
')

VOIDREQUEST(PolyFillArc, `
    MARSHAL(drawable.window.xid, gc.xid)
    OPCODE(71)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    LOCALPARAM(CARD16, `arcs_len')
    LISTPARAM(ARC, `arcs', `arcs_len')
')

VOIDREQUEST(PutImage, `
    OPCODE(72)
    PARAM(CARD8, `format')
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD8, `left_pad')
    PARAM(CARD8, `depth')
    LOCALPARAM(CARD16, `data_len')
    LISTPARAM(BYTE, `data', `data_len')
')

dnl FIXME: data array in reply will include padding, but ought not to.
REQUEST(GetImage, `
    OPCODE(73)
    PARAM(CARD8, `format')
    PARAM(DRAWABLE, `drawable')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `plane_mask')
', `
    REPLY(CARD8, `depth')
    REPLY(VISUALID, `visual')
    PAD(20)
    ARRAYREPLY(BYTE, `data', `R->length * 4')
')

VOIDREQUEST(PolyText8, `
    OPCODE(74)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `items_len')
    LISTPARAM(BYTE, `items', `items_len')
')

VOIDREQUEST(PolyText16, `
    OPCODE(75)
    PAD(1)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `items_len')
    LISTPARAM(BYTE, `items', `items_len')
')

VOIDREQUEST(ImageText8, `
    OPCODE(76)
    PARAM(BYTE, `string_len')
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LISTPARAM(char, `string', `string_len')
')

VOIDREQUEST(ImageText16, `
    OPCODE(77)
    PARAM(BYTE, `string_len')
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LISTPARAM(CHAR2B, `string', `string_len')
')

VOIDREQUEST(CreateColormap, `
    OPCODE(78)
    PARAM(BYTE, `alloc')
    PARAM(COLORMAP, `mid')
    PARAM(WINDOW, `window')
    PARAM(VISUALID, `visual')
')

VOIDREQUEST(FreeColormap, `
    OPCODE(79)
    PAD(1)
    PARAM(COLORMAP, `cmap')
')

VOIDREQUEST(CopyColormapAndFree, `
    OPCODE(80)
    PAD(1)
    PARAM(COLORMAP, `mid')
    PARAM(COLORMAP, `src_cmap')
')

VOIDREQUEST(InstallColormap, `
    OPCODE(81)
    PAD(1)
    PARAM(COLORMAP, `cmap')
')

VOIDREQUEST(UninstallColormap, `
    OPCODE(82)
    PAD(1)
    PARAM(COLORMAP, `cmap')
')

REQUEST(ListInstalledColormaps, `
    OPCODE(83)
    PAD(1)
    PARAM(WINDOW, `window')
', `
    PAD(1)
    REPLY(CARD16, `cmaps_len')
    PAD(22)
    ARRAYREPLY(COLORMAP, `cmaps', `R->cmaps_len')
')

REQUEST(AllocColor, `
    OPCODE(84)
    PAD(1)
    PARAM(COLORMAP, `cmap')
    PARAM(CARD16, `red')
    PARAM(CARD16, `green')
    PARAM(CARD16, `blue')
', `
    PAD(1)
    REPLY(CARD16, `red')
    REPLY(CARD16, `green')
    REPLY(CARD16, `blue')
    PAD(2)
    REPLY(CARD32, `pixel')
')

REQUEST(AllocNamedColor, `
    OPCODE(85)
    PAD(1)
    PARAM(COLORMAP, `cmap')
    PARAM(CARD16, `name_len')
    LISTPARAM(char, `name', `name_len')
', `
    PAD(1)
    REPLY(CARD32, `pixel')
    REPLY(CARD16, `exact_red')
    REPLY(CARD16, `exact_green')
    REPLY(CARD16, `exact_blue')
    REPLY(CARD16, `visual_red')
    REPLY(CARD16, `visual_green')
    REPLY(CARD16, `visual_blue')
')

REQUEST(AllocColorCells, `
    OPCODE(86)
    PARAM(BOOL, `contiguous')
    PARAM(COLORMAP, `cmap')
    PARAM(CARD16, `colors')
    PARAM(CARD16, `planes')
', `
    PAD(1)
    REPLY(CARD16, `pixels_len')
    REPLY(CARD16, `masks_len')
    PAD(20)
    ARRAYREPLY(CARD32, `pixels', `R->pixels_len')
    ARRAYREPLY(CARD32, `masks', `R->masks_len')
')

REQUEST(AllocColorPlanes, `
    OPCODE(87)
    PARAM(BOOL, `contiguous')
    PARAM(COLORMAP, `cmap')
    PARAM(CARD16, `colors')
    PARAM(CARD16, `reds')
    PARAM(CARD16, `greens')
    PARAM(CARD16, `blues')
', `
    PAD(1)
    REPLY(CARD16, `pixels_len')
    PAD(2)
    REPLY(CARD32, `red_mask')
    REPLY(CARD32, `green_mask')
    REPLY(CARD32, `blue_mask')
    PAD(8)
    ARRAYREPLY(CARD32, `pixels', `R->pixels_len')
')

VOIDREQUEST(FreeColors, `
    OPCODE(88)
    PAD(1)
    PARAM(COLORMAP, `cmap')
    PARAM(CARD32, `plane_mask')
    LOCALPARAM(CARD16, `pixels_len')
    LISTPARAM(CARD32, `pixels', `pixels_len')
')

STRUCT(COLORITEM, `
    FIELD(CARD32, `pixel')
    FIELD(CARD16, `red')
    FIELD(CARD16, `green')
    FIELD(CARD16, `blue')
    FIELD(BYTE, `flags')
    PAD(1)
')
    
VOIDREQUEST(StoreColors, `
    MARSHAL(cmap.xid)
    OPCODE(89)
    PAD(1)
    PARAM(COLORMAP, `cmap')
    LOCALPARAM(CARD16, `items_len')
    LISTPARAM(COLORITEM, `items', `items_len')
')

VOIDREQUEST(StoreNamedColor, `
    OPCODE(90)
    PARAM(CARD8, `flags')
    PARAM(COLORMAP, `cmap')
    PARAM(CARD32, `pixel')
    PARAM(CARD16, `name_len')
    LISTPARAM(char, `name', `name_len')
')

STRUCT(RGB, `
    FIELD(CARD16, `red')
    FIELD(CARD16, `green')
    FIELD(CARD16, `blue')
    PAD(2)
')

REQUEST(QueryColors, `
    OPCODE(91)
    PAD(1)
    PARAM(COLORMAP, `cmap')
    LOCALPARAM(CARD16, `pixels_len')
    LISTPARAM(CARD32, `pixels', `pixels_len')
', `
    PAD(1)
    REPLY(CARD16, `colors_len')
    PAD(22)
    ARRAYREPLY(RGB, `colors', `R->colors_len')
')

REQUEST(LookupColor, `
    OPCODE(92)
    PAD(1)
    PARAM(COLORMAP, `cmap')
    PARAM(CARD16, `name_len')
    LISTPARAM(char, `name', `name_len')
', `
    PAD(1)
    REPLY(CARD16, `exact_red')
    REPLY(CARD16, `exact_green')
    REPLY(CARD16, `exact_blue')
    REPLY(CARD16, `visual_red')
    REPLY(CARD16, `visual_green')
    REPLY(CARD16, `visual_blue')
')

VOIDREQUEST(CreateCursor, `
    OPCODE(93)
    PAD(1)
    PARAM(CURSOR, `cid')
    PARAM(PIXMAP, `source')
    PARAM(PIXMAP, `mask')
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
    PARAM(CURSOR, `cid')
    PARAM(FONT, `source_font')
    PARAM(FONT, `mask_font')
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
    PARAM(CURSOR, `cursor')
')

VOIDREQUEST(RecolorCursor, `
    OPCODE(96)
    PAD(1)
    PARAM(CURSOR, `cursor')
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
    PARAM(DRAWABLE, `drawable')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
', `
    PAD(1)
    REPLY(CARD16, `width')
    REPLY(CARD16, `height')
')

REQUEST(QueryExtension, `
    OPCODE(98)
    PAD(1)
    PARAM(CARD16, `name_len')
    LISTPARAM(char, `name', `name_len')
', `
    PAD(1)
    REPLY(BOOL, `present')
    REPLY(CARD8, `major_opcode')
    REPLY(CARD8, `first_event')
    REPLY(CARD8, `first_error')
')

REQUEST(ListExtensions, `
    OPCODE(99)
', `
    REPLY(CARD8, `names_len')
    PAD(24)
    LISTFIELD(STR, `names', `R->names_len')
')

VOIDREQUEST(ChangeKeyboardMapping, `
    OPCODE(100)
    PARAM(CARD8, `keycode_count')
    PARAM(KEYCODE, `first_keycode')
    PARAM(CARD8, `keysyms_per_keycode')
    LISTPARAM(KEYSYM, `keysyms', `keycode_count * keysyms_per_keycode')
')

REQUEST(GetKeyboardMapping, `
    OPCODE(101)
    PAD(1)
    PARAM(KEYCODE, `first_keycode')
    PARAM(CARD8, `count')
', `
    REPLY(BYTE, `keysyms_per_keycode')
    PAD(24)
    ARRAYREPLY(KEYSYM, `keysyms', `R->length * 4')
')

VOIDREQUEST(ChangeKeyboardControl, `
    OPCODE(102)
    PAD(1)
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

REQUEST(GetKeyboardControl, `
    OPCODE(103)
', `
    REPLY(BYTE, `global_auto_repeat')
    REPLY(CARD32, `led_mask')
    REPLY(CARD8, `key_click_percent')
    REPLY(CARD8, `bell_percent')
    REPLY(CARD16, `bell_pitch')
    REPLY(CARD16, `bell_duration')
    PAD(2)
    REPLY(CARD8, `auto_repeats[32]')
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
', `
    PAD(1)
    REPLY(CARD16, `acceleration_numerator')
    REPLY(CARD16, `acceleration_denominator')
    REPLY(CARD16, `threshold')
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
', `
    PAD(1)
    REPLY(CARD16, `timeout')
    REPLY(CARD16, `interval')
    REPLY(BYTE, `prefer_blanking')
    REPLY(BYTE, `allow_exposures')
')

VOIDREQUEST(ChangeHosts, `
    OPCODE(109)
    PARAM(CARD8, `mode')
    PARAM(CARD8, `family')
    PAD(1)
    PARAM(CARD16, `address_len')
    LISTPARAM(char, `address', `address_len')
')

STRUCT(HOST, `
    FIELD(CARD8, `family')
    PAD(1)
    FIELD(CARD16, `address_len')
    ARRAYFIELD(BYTE, `address', `R->address_len')
')

REQUEST(ListHosts, `
    OPCODE(110)
', `
    REPLY(BYTE, `mode')
    REPLY(CARD16, `hosts_len')
    PAD(22)
    LISTFIELD(HOST, `hosts', `R->hosts_len')
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
    PARAM(WINDOW, `window')
    PARAM(CARD16, `atoms_len')
    PARAM(INT16, `delta')
    LISTPARAM(ATOM, `atoms', `atoms_len')
')

VOIDREQUEST(ForceScreenSaver, `
    OPCODE(115)
    PARAM(CARD8, `mode')
')

REQUEST(SetPointerMapping, `
    OPCODE(116)
    PARAM(CARD8, `map_len')
    LISTPARAM(CARD8, `map', `map_len')
', `
    REPLY(BYTE, `status')
')

REQUEST(GetPointerMapping, `
    OPCODE(117)
', `
    REPLY(CARD8, `map_len')
    PAD(24)
    ARRAYREPLY(CARD8, `map', `R->map_len')
')

REQUEST(SetModifierMapping, `
    OPCODE(118)
    PARAM(CARD8, `keycodes_per_modifier')
    LISTPARAM(KEYCODE, `keycodes', `keycodes_per_modifier * 8')
', `
    REPLY(BYTE, `status')
')

REQUEST(GetModifierMapping, `
    OPCODE(119)
', `
    REPLY(CARD8, `keycodes_per_modifier')
    PAD(24)
    ARRAYREPLY(KEYCODE, `keycodes', `R->keycodes_per_modifier * 8')
')

dnl FIXME: NoOperation should allow specifying payload length
dnl but geez, malloc()ing a 262140 byte buffer just so I have something
dnl to hand to write(2) seems silly...!
VOIDREQUEST(NoOperation, `
    OPCODE(127)
')

dnl Pseudo-requests: these functions don't map directly to protocol requests,
dnl but depend on requests in the core protocol, so they're here.

FUNCTION(`int XCBSync', `XCBConnection *c, XCBGenericEvent **e', `
    XCBGetInputFocusRep *reply = XCBGetInputFocusReply(c, XCBGetInputFocus(c), e);
    free(reply);
    return (reply != 0);
')

POPDIV()
ENDXCBGEN
HEADERONLY(REQUIRE(X11, XCB, xcb_extension))
