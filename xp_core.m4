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

REPLY(InputFocus)

REQUEST(InputFocus, GetInputFocus, 43, unused)

REQUEST(void, OpenFont, 45, unused, `
    PARAM(XP_FONT, `fid')
    STRLENPARAM(XP_CARD16, `name', `name_length')
    PAD(2)
    LISTPARAM(char, `name', `name_length')
')
