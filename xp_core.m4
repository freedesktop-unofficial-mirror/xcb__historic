XCBGEN(XP_CORE)
_H
_C`'#include <assert.h>
_C`'#include <stdlib.h>
_C`'#include <stdio.h> /* for perror */
_C`'#include <string.h>
_C
_H`'#include "xcb_conn.h"
_C`'#include "xp_core.h"
_H
_H`'typedef char CHAR2B[2];


/* This function probably belongs here, even though it is
 * the only non-request in the file. */
FUNCTION(`int XCB_Sync', `XCB_Connection *c, xError **e', `
    XCB_GetInputFocus_cookie cookie = XCB_GetInputFocus(c);
    xGetInputFocusReply *reply = XCB_GetInputFocus_Reply(c, cookie, e);
    free(reply);
    return (reply != 0);
')

/* The requests, in major number order. */

VOIDREQUEST(CreateWindow, `
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

VOIDREQUEST(ChangeWindowAttributes, `
    PARAM(Window, `window')
    VALUEPARAM(CARD32, `valueMask', `values')
')

REQUEST(GetWindowAttributes, `PARAM(Window, `id')')

VOIDREQUEST(DestroyWindow, `PARAM(Window, `id')')

VOIDREQUEST(DestroySubwindows, `PARAM(Window, `id')')

VOIDREQUEST(ChangeSaveSet, `
    PARAM(BYTE, `mode')
    PARAM(Window, `window')
')

VOIDREQUEST(ReparentWindow, `
    PARAM(Window, `window')
    PARAM(Window, `parent')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
')

VOIDREQUEST(MapWindow, `PARAM(Window, `id')')

VOIDREQUEST(MapSubwindows, `PARAM(Window, `id')')

VOIDREQUEST(UnmapWindow, `PARAM(Window, `id')')

VOIDREQUEST(UnmapSubwindows, `PARAM(Window, `id')')

VOIDREQUEST(ConfigureWindow, `
    PARAM(Window, `window')
    VALUEPARAM(CARD16, `mask', `values')
')

VOIDREQUEST(CirculateWindow, `
    PARAM(CARD8, `direction')
    PARAM(Window, `window')
')

REQUEST(GetGeometry, `PARAM(Drawable, `id')')

REQUEST(QueryTree, `PARAM(Window, `id')', `REPLYFIELD(Window, `children')')

REQUEST(InternAtom, `
    PARAM(BOOL, `onlyIfExists')
    STRLENFIELD(`name', `nbytes')
    LISTPARAM(char, `name', `nbytes')
')

REQUEST(GetAtomName, `PARAM(Atom, `id')', `REPLYFIELD(CARD8, `name')')

VOIDREQUEST(ChangeProperty, `
    PARAM(CARD8, `mode')
    PARAM(Window, `window')
    PARAM(Atom, `property')
    PARAM(Atom, `type')
    PARAM(CARD8, `format')
    PARAM(CARD32, `nUnits')
    LISTPARAM(BYTE, `data', `nUnits * format / 8')
')

VOIDREQUEST(DeleteProperty, `
    PARAM(Window, `window')
    PARAM(Atom, `property')
')

REQUEST(GetProperty, `
    PARAM(BOOL, `delete')
    PARAM(Window, `window')
    PARAM(Atom, `property')
    PARAM(Atom, `type')
    PARAM(CARD32, `longOffset')
    PARAM(CARD32, `longLength')
', `REPLYFIELD(BYTE, `value')')

REQUEST(ListProperties, `PARAM(Window, `id')', `REPLYFIELD(Atom, `atoms')')

VOIDREQUEST(SetSelectionOwner, `
    PARAM(Window, `window')
    PARAM(Atom, `selection')
    PARAM(Time, `time')
')

REQUEST(GetSelectionOwner, `PARAM(Atom, `id')')

VOIDREQUEST(ConvertSelection, `
    PARAM(Window, `requestor')
    PARAM(Atom, `selection')
    PARAM(Atom, `target')
    PARAM(Atom, `property')
    PARAM(Time, `time')
')

VOIDREQUEST(SendEvent, `
    PARAM(BOOL, `propagate')
    PARAM(Window, `destination')
    PARAM(CARD32, `eventMask')
    dnl FIXME: may fail under WORD64
    PARAM(xEvent, `event')
')

REQUEST(GrabPointer, `
    PARAM(BOOL, `ownerEvents')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `eventMask')
    PARAM(BYTE, `pointerMode')
    PARAM(BYTE, `keyboardMode')
    PARAM(Window, `confineTo')
    PARAM(Cursor, `cursor')
    PARAM(Time, `time')
')

VOIDREQUEST(UngrabPointer, `PARAM(Time, `id')')

VOIDREQUEST(GrabButton, `
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

VOIDREQUEST(UngrabButton, `
    PARAM(CARD8, `button')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `modifiers')
')

VOIDREQUEST(ChangeActivePointerGrab, `
    PARAM(Cursor, `cursor')
    PARAM(Time, `time')
    PARAM(CARD16, `eventMask')
')

REQUEST(GrabKeyboard, `
    PARAM(BOOL, `ownerEvents')
    PARAM(Window, `grabWindow')
    PARAM(Time, `time')
    PARAM(BYTE, `pointerMode')
    PARAM(BYTE, `keyboardMode')
')

VOIDREQUEST(UngrabKeyboard, `PARAM(Time, `id')')

VOIDREQUEST(GrabKey, `
    PARAM(BOOL, `ownerEvents')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `modifiers')
    PARAM(KeyCode, `key')
    PARAM(CARD8, `pointerMode')
    PARAM(CARD8, `keyboardMode')
')

VOIDREQUEST(UngrabKey, `
    PARAM(CARD8, `key')
    PARAM(Window, `grabWindow')
    PARAM(CARD16, `modifiers')
')

VOIDREQUEST(AllowEvents, `
    PARAM(CARD8, `mode')
    PARAM(Time, `time')
')

VOIDREQUEST(GrabServer)

VOIDREQUEST(UngrabServer)

REQUEST(QueryPointer, `PARAM(Window, `id')')

REQUEST(GetMotionEvents, `
    PARAM(Window, `window')
    PARAM(Time, `start')
    PARAM(Time, `stop')
', `REPLYFIELD(xTimecoord, `events')')

REQUEST(TranslateCoords, `
    PARAM(Window, `srcWid')
    PARAM(Window, `dstWid')
    PARAM(INT16, `srcX')
    PARAM(INT16, `srcY')
')

VOIDREQUEST(WarpPointer, `
    PARAM(Window, `srcWid')
    PARAM(Window, `dstWid')
    PARAM(INT16, `srcX')
    PARAM(INT16, `srcY')
    PARAM(CARD16, `srcWidth')
    PARAM(CARD16, `srcHeight')
    PARAM(INT16, `dstX')
    PARAM(INT16, `dstY')
')

VOIDREQUEST(SetInputFocus, `
    PARAM(CARD8, `revertTo')
    PARAM(Window, `focus')
    PARAM(Time, `time')
')

REQUEST(GetInputFocus)

REQUEST(QueryKeymap)

VOIDREQUEST(OpenFont, `
    PARAM(Font, `fid')
    STRLENFIELD(`name', `nbytes')
    LISTPARAM(char, `name', `nbytes')
')

VOIDREQUEST(CloseFont, `PARAM(Font, `id')')

REQUEST(QueryFont, `PARAM(Font, `id')', `
    REPLYFIELD(xFontProp, `properties', `nFontProps')
    REPLYFIELD(xCharInfo, `char_infos')
')

REQUEST(QueryTextExtents, `
    PARAM(Font, `fid')
    LOCALPARAM(CARD16, `nchars')
    EXPRFIELD(`oddLength', `nchars & 1')
    LISTPARAM(CHAR2B, `string', `nchars')
')

dnl FIXME: ListFonts needs an iterator for the reply - a pointer won't do.
REQUEST(ListFonts, `
    PARAM(CARD16, `maxNames')
    STRLENFIELD(`pattern', `nbytes')
    LISTPARAM(char, `pattern', `nbytes')
')

/* The ListFontsWithInfo request is not supported by XCB. */

VOIDREQUEST(SetFontPath, `
    PARAM(CARD16, `nFonts')
    LOCALPARAM(CARD16, `nbytes')
    LISTPARAM(char, `path', `nbytes')
')

dnl FIXME: GetFontPath needs an iterator for the reply - a pointer won't do.
REQUEST(GetFontPath)

VOIDREQUEST(CreatePixmap, `
    PARAM(CARD8, `depth')
    PARAM(Pixmap, `pid')
    PARAM(Drawable, `drawable')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(FreePixmap, `PARAM(Pixmap, `id')')

VOIDREQUEST(CreateGC, `
    PARAM(GContext, `gc')
    PARAM(Drawable, `drawable')
    VALUEPARAM(CARD32, `mask', `values')
')

VOIDREQUEST(ChangeGC, `
    PARAM(GContext, `gc')
    VALUEPARAM(CARD32, `mask', `values')
')

VOIDREQUEST(CopyGC, `
    PARAM(GContext, `srcGC')
    PARAM(GContext, `dstGC')
    PARAM(CARD32, `mask')
')

VOIDREQUEST(SetDashes, `
    PARAM(GContext, `gc')
    PARAM(CARD16, `dashOffset')
    PARAM(CARD16, `nDashes')
    LISTPARAM(CARD8, `dashes', `nDashes')
')

VOIDREQUEST(SetClipRectangles, `
    PARAM(BYTE, `ordering')
    PARAM(GContext, `gc')
    PARAM(INT16, `xOrigin')
    PARAM(INT16, `yOrigin')
    LOCALPARAM(CARD16, `nRectangles')
    LISTPARAM(xRectangle, `rectangles', `nRectangles')
')

VOIDREQUEST(FreeGC, `PARAM(GContext, `id')')

VOIDREQUEST(ClearArea, `
    PARAM(BOOL, `exposures')
    PARAM(Window, `window')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(CopyArea, `
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

VOIDREQUEST(CopyPlane, `
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

VOIDREQUEST(PolyPoint, `
    PARAM(BYTE, `coordMode')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nPoints')
    LISTPARAM(xPoint, `points', `nPoints')
')

VOIDREQUEST(PolyLine, `
    PARAM(BYTE, `coordMode')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nPoints')
    LISTPARAM(xPoint, `points', `nPoints')
')

VOIDREQUEST(PolySegment, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nSegments')
    LISTPARAM(xSegment, `segments', `nSegments')
')

VOIDREQUEST(PolyRectangle, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nRectangles')
    LISTPARAM(xRectangle, `rectangles', `nRectangles')
')

VOIDREQUEST(PolyArc, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nArcs')
    LISTPARAM(xArc, `arcs', `nArcs')
')

VOIDREQUEST(FillPoly, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(CARD8, `shape')
    PARAM(CARD8, `coordMode')
    LOCALPARAM(CARD16, `nPoints')
    LISTPARAM(xPoint, `points', `nPoints')
')

VOIDREQUEST(PolyFillRectangle, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nRectangles')
    LISTPARAM(xRectangle, `rectangles', `nRectangles')
')

VOIDREQUEST(PolyFillArc, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    LOCALPARAM(CARD16, `nArcs')
    LISTPARAM(xArc, `arcs', `nArcs')
')

VOIDREQUEST(PutImage, `
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

REQUEST(GetImage, `
    PARAM(CARD8, `format')
    PARAM(Drawable, `drawable')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `planeMask')
', `REPLYFIELD(BYTE, `data')')

VOIDREQUEST(PolyText8, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `nbytes')
    LISTPARAM(BYTE, `items', `nbytes')
')

VOIDREQUEST(PolyText16, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LOCALPARAM(CARD16, `nbytes')
    LISTPARAM(BYTE, `items', `nbytes')
')

VOIDREQUEST(ImageText8, `
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    STRLENFIELD(`string', `nChars')
    LISTPARAM(char, `string', `nChars')
')

VOIDREQUEST(ImageText16, `
    PARAM(BYTE, `nChars')
    PARAM(Drawable, `drawable')
    PARAM(GContext, `gc')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    LISTPARAM(CHAR2B, `string', `nChars')
')

VOIDREQUEST(CreateColormap, `
    PARAM(BYTE, `alloc')
    PARAM(Colormap, `mid')
    PARAM(Window, `window')
    PARAM(VisualID, `visual')
')

VOIDREQUEST(FreeColormap, `PARAM(Colormap, `id')')

VOIDREQUEST(CopyColormapAndFree, `
    PARAM(Colormap, `mid')
    PARAM(Colormap, `srcCmap')
')

VOIDREQUEST(InstallColormap, `PARAM(Colormap, `id')')

VOIDREQUEST(UninstallColormap, `PARAM(Colormap, `id')')

REQUEST(ListInstalledColormaps, `PARAM(Window, `id')', `
    REPLYFIELD(Colormap, `cmaps', `nColormaps')
')

dnl **REQUEST(AllocColor, `
dnl     PARAM(Colormap, `cmap')
dnl     PARAM(CARD16, `red')
dnl     PARAM(CARD16, `green')
dnl     PARAM(CARD16, `blue')
dnl ')

dnl **REQUEST(AllocNamedColor, `
dnl     PARAM(Colormap, `cmap)
dnl ')

dnl TODO: AllocColorCells
dnl TODO: AllocColorPlanes

dnl **VOIDREQUEST(FreeColors, `
dnl     PARAM(Colormap, `cmap')
dnl     PARAM(CARD32, `planeMask')
dnl ')
    
dnl **VOIDREQUEST(StoreColors, `
dnl     PARAM(Colormap, `cmap')
dnl ')

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
dnl TODO: ChangeKeyboardControl
dnl TODO: GetKeyboardControl
dnl
VOIDREQUEST(Bell, `PARAM(INT8, `percent')')

dnl TODO: ChangePointerControl
dnl TODO: GetPointerControl
dnl TODO: SetScreenSaver
dnl TODO: GetScreenSaver
dnl TODO: ChangeHosts
dnl TODO: ListHosts
dnl TODO: SetAccessControl
dnl TODO: SetCloseDownMode
dnl TODO: KillClient
dnl
VOIDREQUEST(RotateProperties, `
    PARAM(Window, `window')
    PARAM(CARD16, `nAtoms')
    PARAM(INT16, `nPositions')
    LISTPARAM(Atom, `atoms', `nAtoms')
')

dnl TODO: ForceScreenSaver
dnl TODO: SetPointerMapping
dnl TODO: GetPointerMapping
dnl TODO: SetModifierMapping
dnl TODO: GetModifierMapping
dnl 
dnl FIXME: NoOperation should allow specifying payload length
dnl but geez, malloc()ing a 262140 byte buffer just so I have something
dnl to hand to write(2) seems silly...!
VOIDREQUEST(NoOperation)
_H
ENDXCBGEN
