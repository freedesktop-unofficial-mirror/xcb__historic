STARTHEADER
_C`'#include <assert.h>
_C`'#include <stdlib.h>
_C`'#include <stdio.h> /* for perror */
_C`'#include <string.h>
_C
_H`'#include "xcb_conn.h"
_C`'#include "xp_core.h"
_H
_H`'typedef char CHAR2B[2];

FUNCTION(`', `XCB_Connection *XP_Connect', `', `
    int fd, screen;
    XCB_Connection *c;
    fd = XCB_Open(getenv("DISPLAY"), &screen);
    if(fd == -1)
    {
        perror("XCB_Open");
        abort();
    }

    c = XCB_Connect(fd);
    if(!c)
    {
        perror("XCB_Connect");
        abort();
    }

    return c;
')
_C
FUNCTION(`', `int XP_Flush', `XCB_Connection *c', `
    pthread_mutex_lock(&c->locked);
    XCB_Flush(c);
    pthread_mutex_unlock(&c->locked);
    return 1;
')
_C
FUNCTION(`', `int XP_Sync', `XCB_Connection *c, xError **e', `
    XCB_GetInputFocus_cookie cookie = XP_GetInputFocus(c);
    xGetInputFocusReply *reply = XP_GetInputFocus_Get_Reply(c, cookie, e);
    free(reply);
    return (reply != 0);
')

REQUEST(void, CreateWindow, `
    PARAM(CARD8, `depth')
    PARAM(Window, `wid')
    PARAM(Window, `parent')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD16, `borderWidth')
    PARAM(CARD16, `class')
    PARAM(VisualID, `visual')
    VALUEPARAM(CARD32, `mask', `values')
')

REQUEST(void, ChangeWindowAttributes, `
    PARAM(Window, `window')
    VALUEPARAM(CARD32, `valueMask', `values')
')

REQUEST(GetWindowAttributes, GetWindowAttributes, `PARAM(Window, `id')')

REQUEST(void, DestroyWindow, `PARAM(Window, `id')')

REQUEST(void, DestroySubwindows, `PARAM(Window, `id')')

REQUEST(void, ChangeSaveSet, `
    PARAM(BYTE, `mode')
    PARAM(Window, `window')
')

REQUEST(void, ReparentWindow, `
    PARAM(Window, `window')
    PARAM(Window, `parent')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
')

REQUEST(void, MapWindow, `PARAM(Window, `id')')

REQUEST(void, MapSubwindows, `PARAM(Window, `id')')

REQUEST(void, UnmapWindow, `PARAM(Window, `id')')

REQUEST(void, UnmapSubwindows, `PARAM(Window, `id')')

REQUEST(void, ConfigureWindow, `
    PARAM(Window, `window')
    VALUEPARAM(CARD16, `mask', `values')
')

REQUEST(void, CirculateWindow, `
    PARAM(CARD8, `direction')
    PARAM(Window, `window')
')

REQUEST(GetGeometry, GetGeometry, `PARAM(Drawable, `id')')

REQUEST(QueryTree, QueryTree, `PARAM(Window, `id')')

REQUEST(InternAtom, InternAtom, `
    PARAM(BOOL, `onlyIfExists')
    STRLENPARAM(`name', `nbytes')
    LISTPARAM(char, `name', `out->nbytes')
')

REQUEST(void, ChangeProperty, `
    PARAM(CARD8, `mode')
    PARAM(Window, `window')
    PARAM(Atom, `property')
    PARAM(Atom, `type')
    PARAM(CARD8, `format')
    PARAM(CARD32, `nUnits')
    LISTPARAM(BYTE, `data', `out->nUnits * format / 8')
')

REQUEST(void, DeleteProperty, `
    PARAM(Window, `window')
    PARAM(Atom, `property')
')

REQUEST(GetProperty, GetProperty, `
    PARAM(BOOL, `delete')
    PARAM(Window, `window')
    PARAM(Atom, `property')
    PARAM(Atom, `type')
    PARAM(CARD32, `longOffset')
    PARAM(CARD32, `longLength')
')

REQUEST(void, RotateProperties, `
    PARAM(Window, `window')
    PARAM(CARD16, `nAtoms')
    PARAM(INT16, `nPositions')
    LISTPARAM(Atom, `atoms', `out->nAtoms')
')

REQUEST(ListProperties, ListProperties, `PARAM(Window, `id')')

REQUEST(void, SetSelectionOwner, `
    PARAM(Window, `window')
    PARAM(Atom, `selection')
    PARAM(Time, `time')
')

REQUEST(GetSelectionOwner, GetSelectionOwner, `PARAM(Atom, `id')')

REQUEST(void, ConvertSelection, `
    PARAM(Window, `requestor')
    PARAM(Atom, `selection')
    PARAM(Atom, `target')
    PARAM(Atom, `property')
    PARAM(Time, `time')
')

REQUEST(void, SendEvent, `
    PARAM(BOOL, `propagate')
    PARAM(Window, `destination')
    PARAM(CARD32, `eventMask')
    dnl FIXME: will fail under WORD64
    PARAM(xEvent, `event')
')

REQUEST(GrabPointer, GrabPointer, `
    PARAM(BOOL, `ownerEvents')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `eventMask')
    PARAM(BYTE, `pointerMode')
    PARAM(BYTE, `keyboardMode')
    PARAM(Window, `confineTo')
    PARAM(Cursor, `cursor')
    PARAM(Time, `time')
')

REQUEST(void, UngrabPointer, `PARAM(Time, `id')')

REQUEST(void, GrabButton, `
    PARAM(BOOL, `ownerEvents')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `eventMask')
    PARAM(CARD8, `pointerMode')
    PARAM(CARD8, `keyboardMode')
    PARAM(Window, `confineTo')
    PARAM(Cursor, `cursor')
    PARAM(CARD8, `button')
    PARAM(CARD16, `modifiers')
')

REQUEST(void, UngrabButton, `
    PARAM(CARD8, `button')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `modifiers')
')

REQUEST(void, ChangeActivePointerGrab, `
    PARAM(Cursor, `cursor')
    PARAM(Time, `time')
    PARAM(CARD16, `eventMask')
')

REQUEST(GrabKeyboard, GrabKeyboard, `
    PARAM(BOOL, `ownerEvents')
    PARAM(Window, `grabWindow')
    PARAM(Time, `time')
    PARAM(BYTE, `pointerMode')
    PARAM(BYTE, `keyboardMode')
')

REQUEST(void, UngrabKeyboard, `PARAM(Time, `id')')

REQUEST(void, GrabKey, `
    PARAM(BOOL, `ownerEvents')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `modifiers')
    PARAM(KeyCode, `key')
    PARAM(CARD8, `pointerMode')
    PARAM(CARD8, `keyboardMode')
')

REQUEST(void, UngrabKey, `
    PARAM(CARD8, `key')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `modifiers')
')

REQUEST(void, AllowEvents, `
    PARAM(CARD8, `mode')
    PARAM(Time, `time')
')

REQUEST(void, GrabServer)

REQUEST(void, UngrabServer)

REQUEST(QueryPointer, QueryPointer, `PARAM(Window, `id')')

REQUEST(GetMotionEvents, GetMotionEvents, `
    PARAM(Window, `window')
    PARAM(Time, `start')
    PARAM(Time, `stop')
')

REQUEST(TranslateCoords, TranslateCoords, `
    PARAM(Window, `srcWid')
    PARAM(Window, `dstWid')
    PARAM(INT16, `srcX')
    PARAM(INT16, `srcY')
')

REQUEST(void, WarpPointer, `
    PARAM(Window, `srcWid')
    PARAM(Window, `dstWid')
    PARAM(INT16, `srcX')
    PARAM(INT16, `srcY')
    PARAM(CARD16, `srcWidth')
    PARAM(CARD16, `srcHeight')
    PARAM(INT16, `dstX')
    PARAM(INT16, `dstY')
')

REQUEST(void, SetInputFocus, `
    PARAM(CARD8, `revertTo')
    PARAM(Window, `focus')
    PARAM(Time, `time')
')

REQUEST(GetInputFocus, GetInputFocus)

REQUEST(QueryKeymap, QueryKeymap)

REQUEST(void, OpenFont, `
    PARAM(Font, `fid')
    STRLENPARAM(`name', `nbytes')
    LISTPARAM(char, `name', `out->nbytes')
')

REQUEST(void, CloseFont, `PARAM(Font, `id')')

REQUEST(QueryFont, QueryFont, `
    PARAM(Font, `id')
')

REQUEST(QueryTextExtents, QueryTextExtents, `
    PARAM(Font, `fid')
    LOCALPARAM(CARD16, `nchars')
    LISTPARAM(CHAR2B, `string', `nchars')
pushdiv(_outdiv)dnl
TAB()out->oddLength = (XP_PAD(nchars * sizeof(CHAR2B)) == 2) ? 1 : 0;
popdiv()
')

REQUEST(ListFonts, ListFonts, `
    PARAM(CARD16, `maxNames')
    STRLEN(`pattern', `nbytes')
    LISTPARAM(char, `pattern', `out->nbytes')
')

dnl FIXME: can return more than one reply, but only the first is processed
REQUEST(ListFontsWithInfo, ListFontsWithInfo, `
    PARAM(CARD16, `maxNames')
    STRLEN(`pattern', `nbytes')
    LISTPARAM(char, `pattern', `out->nbytes')
')

dnl TODO: SetFontPath
dnl
REQUEST(GetFontPath, GetFontPath)

REQUEST(void, CreatePixmap, `
    PARAM(CARD8, `depth')
    PARAM(Pixmap, `pid')
    PARAM(Drawable, `drawable')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

REQUEST(void, FreePixmap, `PARAM(Pixmap, `id')')

REQUEST(void, CreateGC, `
    PARAM(GContext, `gc')
    PARAM(Drawable, `drawable')
    VALUEPARAM(CARD32, `mask', `values')
')

REQUEST(void, ChangeGC, `
    PARAM(GContext, `gc')
    VALUEPARAM(CARD32, `mask', `values')
')

REQUEST(void, CopyGC, `
    PARAM(GContext, `srcGC')
    PARAM(GContext, `dstGC')
    PARAM(CARD32, `mask')
')

REQUEST(void, SetDashes, `
    PARAM(GContext, `gc')
    PARAM(CARD16, `dashOffset')
    PARAM(CARD16, `nDashes')
    LISTPARAM(CARD8, `dashes', `out->nDashes')
')

REQUEST(void, SetClipRectangles, `
    PARAM(BYTE, `ordering')
    PARAM(GContext, `gc')
    PARAM(INT16, `xOrigin')
    PARAM(INT16, `yOrigin')
    LOCALPARAM(CARD16, `nRectangles')
    LISTPARAM(xRectangle, `rectangles', `nRectangles')
')

REQUEST(void, FreeGC, `PARAM(GContext, `id')')

REQUEST(void, ClearArea, `
    PARAM(BOOL, `exposures')
    PARAM(Window, `window')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

REQUEST(void, CopyArea, `
    PARAM(Drawable, `srcDrawable')
    PARAM(Drawable, `dstDrawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `srcX')
    PARAM(INT16, `srcY')
    PARAM(INT16, `dstX')
    PARAM(INT16, `dstY')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

REQUEST(void, CopyPlane, `
    PARAM(Drawable, `srcDrawable')
    PARAM(Drawable, `dstDrawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `srcX')
    PARAM(INT16, `srcY')
    PARAM(INT16, `dstX')
    PARAM(INT16, `dstY')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `bitPlane')
')

REQUEST(void, PolyPoint, `
    PARAM(BYTE, `coordMode')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nPoints')
    LISTPARAM(xPoint, `points', `nPoints')
')

REQUEST(void, PolyLine, `
    PARAM(BYTE, `coordMode')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nLines')
    LISTPARAM(xPoint, `lines', `nLines')
')

REQUEST(void, PolySegment, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nSegments')
    LISTPARAM(xSegment, `segments', `nSegments')
')

REQUEST(void, PolyRectangle, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nRectangles')
    LISTPARAM(xRectangle, `rectangles', `nRectangles')
')

REQUEST(void, PolyArc, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nArcs')
    LISTPARAM(xArc, `arcs', `nArcs')
')

REQUEST(void, FillPoly, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(CARD8, `shape')
    PARAM(CARD8, `coordMode')
    LOCALPARAM(CARD16, `nPoints')
    LISTPARAM(xPoint, `points', `nPoints')
')

REQUEST(void, PolyFillRectangle, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nRectangles')
    LISTPARAM(xRectangle, `rectangles', `nRectangles')
')

REQUEST(void, PolyFillArc, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nArcs')
    LISTPARAM(xArc, `arcs', `nArcs')
')

REQUEST(void, PutImage, `
    PARAM(CARD8, `format')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(INT16, `dstX')
    PARAM(INT16, `dstY')
    PARAM(CARD8, `leftPad')
    PARAM(CARD8, `depth')
    LOCALPARAM(CARD16, `nbytes')
    LISTPARAM(BYTE, `data', `nbytes')
')

REQUEST(GetImage, GetImage, `
    PARAM(CARD8, `format')
    PARAM(Drawable, `drawable')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `planeMask')
')

REQUEST(void, PolyText8, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `nbytes')
    LISTPARAM(BYTE, `items', `nbytes')
')

REQUEST(void, PolyText16, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `nbytes')
    LISTPARAM(BYTE, `items', `nbytes')
')

dnl TODO: ImageText8
dnl TODO: ImageText16
dnl TODO: CreateColormap
dnl TODO: FreeColormap
dnl TODO: CopyColormapAndFree
dnl TODO: InstallColormap
dnl TODO: UninstallColormap
dnl TODO: ListInstalledColormaps
dnl TODO: AllocColor
dnl TODO: AllocNamedColor
dnl TODO: AllocColorCells
dnl TODO: AllocColorPlanes
dnl TODO: FreeColors
dnl TODO: StoreColors
dnl TODO: StoreNamedColor
dnl TODO: QueryColors
dnl TODO: LookupColor
dnl TODO: CreateCursor
dnl TODO: CreateGlyphCursor
dnl TODO: FreeCursor
dnl TODO: RecolorCursor
dnl TODO: QueryBestSize
dnl TODO: QueryExtension
dnl TODO: ListExtensions
dnl TODO: ChangeKeyboardMapping
dnl TODO: GetKeyboardMapping
dnl
REQUEST(void, Bell, `PARAM(INT8, `percent')')

dnl FIXME: NoOperation should allow specifying payload length
dnl but geez, malloc()ing a 262140 byte buffer just so I have something
dnl to hand to write(2) seems silly...!
REQUEST(void, NoOperation)
