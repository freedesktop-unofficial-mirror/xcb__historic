XCBGEN(xcb_types, `
Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')
/* Basic types */
dnl from Xmd.h
dnl XXX: 64-bit architectures untested with XCB; probably won't work.

#ifdef CRAY
#define WORD64                          /* 64-bit architecture */
#endif
#if defined(__alpha) || defined(__alpha__) || \
    defined(__ia64__) || defined(ia64)
#define LONG64                          /* 32/64-bit architecture */
#endif

#if defined(__hppa__) && defined(__LP64__)
#define LONG64                          /* 32/64-bit architecture */
#endif

#ifdef __sgi
#if (_MIPS_SZLONG == 64)
#define LONG64
#endif
#endif

#ifdef WORD64
#define MUSTCOPY
#endif /* WORD64 */

/*
 * Bitfield suffixes for the protocol structure elements, if you
 * need them.  Note that bitfields are not guarranteed to be signed
 * (or even unsigned) according to ANSI C.
 */
#ifdef WORD64
typedef long INT64;
typedef unsigned long CARD64;
#define B32 :32
#define B16 :16
#ifdef UNSIGNEDBITFIELDS
typedef unsigned int INT32;
typedef unsigned int INT16;
#else
#ifdef __STDC__
typedef signed int INT32;
typedef signed int INT16;
#else
typedef int INT32;
typedef int INT16;
#endif
#endif
#else
#define B32
#define B16
#ifdef LONG64
typedef long INT64;
typedef int INT32;
#else
typedef long INT32;
#endif
typedef short INT16;
#endif

#if defined(__STDC__) || defined(sgi) || defined(AIXV3)
typedef signed char    INT8;
#else
typedef char           INT8;
#endif

#ifdef LONG64
typedef unsigned long CARD64;
typedef unsigned int CARD32;
#else
typedef unsigned long CARD32;
#endif
typedef unsigned short CARD16;
typedef unsigned char  CARD8;

typedef CARD32          BITS32;
typedef CARD16          BITS16;

#ifndef __EMX__
typedef CARD8           BYTE;
typedef CARD8           BOOL;
#else /* __EMX__ */
/*
 * This is bad style, but the central include file <os2.h> declares them
 * as well
 */
#define BYTE            CARD8
#define BOOL            CARD8
#endif /* __EMX__ */


/* Core protocol types */

/* predeclare from xcb_conn */
struct XCB_Connection;
CARD32 XCB_Generate_ID(struct XCB_Connection *c);

STRUCT(CHAR2B, `
    FIELD(CARD8, `byte1')
    FIELD(CARD8, `byte2')
')

XIDTYPE(WINDOW)

XIDTYPE(PIXMAP)

XIDTYPE(CURSOR)

XIDTYPE(FONT)

XIDTYPE(GCONTEXT)

XIDTYPE(COLORMAP)

XIDTYPE(ATOM)

UNION(DRAWABLE, `
    FIELD(WINDOW, `window')
    FIELD(PIXMAP, `pixmap')
')

UNION(FONTABLE, `
    FIELD(FONT, `font')
    FIELD(GCONTEXT, `gcontext')
')

STRUCT(VISUALID, `FIELD(CARD32, `id')')

STRUCT(TIMESTAMP, `FIELD(CARD32, `id')')

STRUCT(KEYSYM, `FIELD(CARD32, `id')')

STRUCT(KEYCODE, `FIELD(CARD8, `id')')

STRUCT(BUTTON, `FIELD(CARD8, `id')')

STRUCT(POINT, `
    FIELD(INT16, `x')
    FIELD(INT16, `y')
')

STRUCT(RECTANGLE, `
    FIELD(INT16, `x')
    FIELD(INT16, `y')
    FIELD(CARD16, `width')
    FIELD(CARD16, `height')
')

STRUCT(ARC, `
    FIELD(INT16, `x')
    FIELD(INT16, `y')
    FIELD(CARD16, `width')
    FIELD(CARD16, `height')
    FIELD(INT16, `angle1')
    FIELD(INT16, `angle2')
')

/* Connection setup-related types */

STRUCT(FORMAT, `
    FIELD(CARD8, `depth')
    FIELD(CARD8, `bits_per_pixel')
    FIELD(CARD8, `scanline_pad')
    PAD(5)
')

STRUCT(SCREEN, `
    FIELD(WINDOW, `root')
    FIELD(COLORMAP, `default_colormap')
    FIELD(CARD32, `white_pixel')
    FIELD(CARD32, `black_pixel')
    FIELD(CARD32, `current_input_masks')
    FIELD(CARD16, `width_in_pixels')
    FIELD(CARD16, `height_in_pixels')
    FIELD(CARD16, `width_in_millimeters')
    FIELD(CARD16, `height_in_millimeters')
    FIELD(CARD16, `min_installed_maps')
    FIELD(CARD16, `max_installed_maps')
    FIELD(VISUALID, `root_visual')
    FIELD(BYTE, `backing_stores')
    FIELD(BOOL, `save_unders')
    FIELD(CARD8, `root_depth')
    FIELD(CARD8, `allowed_depths_len')
    dnl LISTFIELD(DEPTH, `allowed_depths', `R->allowed_depths_len')
')

STRUCT(DEPTH, `
    FIELD(CARD8, `depth')
    PAD(1)
    FIELD(CARD16, `visuals_len')
    PAD(4)
    dnl LISTFIELD(VISUALTYPE, `visuals', `R->visuals_len')
')

STRUCT(VISUALTYPE, `
    FIELD(VISUALID, `visual_id')
    FIELD(CARD8, `class')
    FIELD(CARD8, `bits_per_rgb_value')
    FIELD(CARD16, `colormap_entries')
    FIELD(CARD32, `red_mask')
    FIELD(CARD32, `green_mask')
    FIELD(CARD32, `blue_mask')
    PAD(4)
')

STRUCT(XCB_ConnSetup_Req, `
    FIELD(CARD8, `byte_order')
    PAD(1)
    FIELD(CARD16, `protocol_major_version')
    FIELD(CARD16, `protocol_minor_version')
    FIELD(CARD16, `authorization_protocol_name_len')
    FIELD(CARD16, `authorization_protocol_data_len')
    dnl LISTFIELD(char, `authorization_protocol_name', `R->authorization_protocol_name_len')
    dnl LISTFIELD(char, `authorization_protocol_data', `R->authorization_protocol_data_len')
')

STRUCT(XCB_ConnSetup_Generic_Rep, `
    FIELD(CARD8, `status')
    PAD(5)
    FIELD(CARD16, `length')
')

STRUCT(XCB_ConnSetup_Failed_Rep, `
    FIELD(CARD8, `status') dnl always 0 -> Failed
    FIELD(CARD8, `reason_len')
    FIELD(CARD16, `protocol_major_version')
    FIELD(CARD16, `protocol_minor_version')
    FIELD(CARD16, `length')
    dnl LISTFIELD(char, `reason', `R->reason_length')
')

STRUCT(XCB_ConnSetup_Authenticate_Rep, `
    FIELD(CARD8, `status') dnl always 2 -> Authenticate
    PAD(5)
    FIELD(CARD16, `length')
    dnl LISTFIELD(char, `reason', `R->length * 4')
')

STRUCT(XCB_ConnSetup_Success_Rep, `
    FIELD(CARD8, `status') dnl always 1 -> Success
    PAD(1)
    FIELD(CARD16, `protocol_major_version')
    FIELD(CARD16, `protocol_minor_version')
    FIELD(CARD16, `length')
    FIELD(CARD32, `release_number')
    FIELD(CARD32, `resource_id_base')
    FIELD(CARD32, `resource_id_mask')
    FIELD(CARD32, `motion_buffer_size')
    FIELD(CARD16, `vendor_len')
    FIELD(CARD16, `maximum_request_length')
    FIELD(CARD8, `roots_len')
    FIELD(CARD8, `pixmap_formats_len')
    FIELD(CARD8, `image_byte_order')
    FIELD(CARD8, `bitmap_format_bit_order')
    FIELD(CARD8, `bitmap_format_scanline_unit')
    FIELD(CARD8, `bitmap_format_scanline_pad')
    FIELD(KEYCODE, `min_keycode')
    FIELD(KEYCODE, `max_keycode')
    PAD(4)
    dnl LISTFIELD(char, `vendor', `R->vendor_len')
    dnl LISTFIELD(FORMAT, `pixmap_formats', `R->pixmap_formats_len')
    dnl LISTFIELD(SCREEN, `roots', `R->roots_len')
')

/* Pre-defined constants */

COMMENT(X_TCP_PORT + display number = server port for TCP transport)
CONSTANT(int, `X_TCP_PORT', `6000')

COMMENT(current protocol version)
CONSTANT(CARD16, `X_PROTOCOL', `11')

COMMENT(current minor version)
CONSTANT(CARD16, `X_PROTOCOL_REVISION', `0')

dnl XXX: everything after here probably belongs in xp_core.m4. It came from
dnl X.h et al.

CONSTANT(BOOL, `TRUE', `1')
CONSTANT(BOOL, `FALSE', `0')

COMMENT(universal null resource or null atom)
CONSTANT(CARD32, `None', `0L')

COMMENT(background pixmap in CreateWindow and ChangeWindowAttributes)
CONSTANT(PIXMAP, `ParentRelative', `1L')

COMMENT(border pixmap in CreateWindow and ChangeWindowAttributes
special VisualID and special window class passed to CreateWindow)
CONSTANT(PIXMAP, `CopyFromParent', `0L')

COMMENT(destination window in SendEvent)
CONSTANT(WINDOW, `PointerWindow', `0L')

COMMENT(destination window in SendEvent)
CONSTANT(WINDOW, `InputFocus', `1L')

COMMENT(focus window in SetInputFocus)
CONSTANT(WINDOW, `PointerRoot', `1L')

COMMENT(special Atom, passed to GetProperty)
CONSTANT(ATOM, `AnyPropertyType', `0L')

COMMENT(special Key Code, passed to GrabKey)
CONSTANT(KEYCODE, `AnyKey', `0L')

COMMENT(special Button Code, passed to GrabButton)
CONSTANT(BUTTON, `AnyButton', `0L')

COMMENT(special Resource ID passed to KillClient)
CONSTANT(CARD32, `AllTemporary', `0L')

COMMENT(special Time)
CONSTANT(TIMESTAMP, `CurrentTime', `0L')

COMMENT(special KeySym)
CONSTANT(KEYSYM, `NoSymbol', `0L')

COMMENT(Input Event Masks. Used as event-mask window attribute and as
arguments to Grab requests.  Not to be confused with event names.)

#define NoEventMask                     0L
#define KeyPressMask                    (1L<<0)  
#define KeyReleaseMask                  (1L<<1)  
#define ButtonPressMask                 (1L<<2)  
#define ButtonReleaseMask               (1L<<3)  
#define EnterWindowMask                 (1L<<4)  
#define LeaveWindowMask                 (1L<<5)  
#define PointerMotionMask               (1L<<6)  
#define PointerMotionHintMask           (1L<<7)  
#define Button1MotionMask               (1L<<8)  
#define Button2MotionMask               (1L<<9)  
#define Button3MotionMask               (1L<<10) 
#define Button4MotionMask               (1L<<11) 
#define Button5MotionMask               (1L<<12) 
#define ButtonMotionMask                (1L<<13) 
#define KeymapStateMask                 (1L<<14)
#define ExposureMask                    (1L<<15) 
#define VisibilityChangeMask            (1L<<16) 
#define StructureNotifyMask             (1L<<17) 
#define ResizeRedirectMask              (1L<<18) 
#define SubstructureNotifyMask          (1L<<19) 
#define SubstructureRedirectMask        (1L<<20) 
#define FocusChangeMask                 (1L<<21) 
#define PropertyChangeMask              (1L<<22) 
#define ColormapChangeMask              (1L<<23) 
#define OwnerGrabButtonMask             (1L<<24) 

COMMENT(Enter/Leave event)

#define ELFlagFocus        (1<<0)
#define ELFlagSameScreen   (1<<1)

COMMENT(Event names are defined in xp_core.h.)

COMMENT(Key masks. Used as modifiers to GrabButton and GrabKey, results of
QueryPointer, state in various key-, mouse-, and button-related events.)

#define ShiftMask               (1<<0)
#define LockMask                (1<<1)
#define ControlMask             (1<<2)
#define Mod1Mask                (1<<3)
#define Mod2Mask                (1<<4)
#define Mod3Mask                (1<<5)
#define Mod4Mask                (1<<6)
#define Mod5Mask                (1<<7)

COMMENT(modifier names.  Used to build a SetModifierMapping request or
to read a GetModifierMapping request.  These correspond to the
masks defined above.)

#define ShiftMapIndex           0
#define LockMapIndex            1
#define ControlMapIndex         2
#define Mod1MapIndex            3
#define Mod2MapIndex            4
#define Mod3MapIndex            5
#define Mod4MapIndex            6
#define Mod5MapIndex            7

COMMENT(button masks.  Used in same manner as Key masks above. Not to be
confused with button names below.)

#define Button1Mask             (1<<8)
#define Button2Mask             (1<<9)
#define Button3Mask             (1<<10)
#define Button4Mask             (1<<11)
#define Button5Mask             (1<<12)

#define AnyModifier             (1<<15)  /* used in GrabButton, GrabKey */

COMMENT(button names. Used as arguments to GrabButton and as detail in
ButtonPress and ButtonRelease events.  Not to be confused with button masks
above. Note that 0 is already defined above as "AnyButton".)

#define Button1                 1
#define Button2                 2
#define Button3                 3
#define Button4                 4
#define Button5                 5

COMMENT(Notify modes)

#define NotifyNormal            0
#define NotifyGrab              1
#define NotifyUngrab            2
#define NotifyWhileGrabbed      3

#define NotifyHint              1       /* for MotionNotify events */

COMMENT(Notify detail)

#define NotifyAncestor          0
#define NotifyVirtual           1
#define NotifyInferior          2
#define NotifyNonlinear         3
#define NotifyNonlinearVirtual  4
#define NotifyPointer           5
#define NotifyPointerRoot       6
#define NotifyDetailNone        7

COMMENT(Visibility notify)

#define VisibilityUnobscured            0
#define VisibilityPartiallyObscured     1
#define VisibilityFullyObscured         2

COMMENT(Circulation request)

#define PlaceOnTop              0
#define PlaceOnBottom           1

COMMENT(protocol families)

#define FamilyInternet          0
#define FamilyDECnet            1
#define FamilyChaos             2

COMMENT(Property notification)

#define PropertyNewValue        0
#define PropertyDelete          1

COMMENT(Color Map notification)

#define ColormapUninstalled     0
#define ColormapInstalled       1

COMMENT(GrabPointer, GrabButton, GrabKeyboard, GrabKey Modes)

#define GrabModeSync            0
#define GrabModeAsync           1

COMMENT(GrabPointer, GrabKeyboard reply status)

#define GrabSuccess             0
#define AlreadyGrabbed          1
#define GrabInvalidTime         2
#define GrabNotViewable         3
#define GrabFrozen              4

COMMENT(AllowEvents modes)

#define AsyncPointer            0
#define SyncPointer             1
#define ReplayPointer           2
#define AsyncKeyboard           3
#define SyncKeyboard            4
#define ReplayKeyboard          5
#define AsyncBoth               6
#define SyncBoth                7

COMMENT(Used in SetInputFocus, GetInputFocus)

#define RevertToNone            (int)None
#define RevertToPointerRoot     (int)PointerRoot
#define RevertToParent          2

COMMENT(Error codes are defined in xp_core.h.)

COMMENT(Window classes used by CreateWindow.
Note that CopyFromParent is already defined as 0 above.)

#define InputOutput             1
#define InputOnly               2

COMMENT(Window attributes for CreateWindow and ChangeWindowAttributes.)

#define CWBackPixmap            (1L<<0)
#define CWBackPixel             (1L<<1)
#define CWBorderPixmap          (1L<<2)
#define CWBorderPixel           (1L<<3)
#define CWBitGravity            (1L<<4)
#define CWWinGravity            (1L<<5)
#define CWBackingStore          (1L<<6)
#define CWBackingPlanes         (1L<<7)
#define CWBackingPixel          (1L<<8)
#define CWOverrideRedirect      (1L<<9)
#define CWSaveUnder             (1L<<10)
#define CWEventMask             (1L<<11)
#define CWDontPropagate         (1L<<12)
#define CWColormap              (1L<<13)
#define CWCursor                (1L<<14)

COMMENT(ConfigureWindow structure)

#define CWX                     (1<<0)
#define CWY                     (1<<1)
#define CWWidth                 (1<<2)
#define CWHeight                (1<<3)
#define CWBorderWidth           (1<<4)
#define CWSibling               (1<<5)
#define CWStackMode             (1<<6)

COMMENT(Bit Gravity)

#define ForgetGravity           0
#define NorthWestGravity        1
#define NorthGravity            2
#define NorthEastGravity        3
#define WestGravity             4
#define CenterGravity           5
#define EastGravity             6
#define SouthWestGravity        7
#define SouthGravity            8
#define SouthEastGravity        9
#define StaticGravity           10

COMMENT(Window gravity + bit gravity above)

#define UnmapGravity            0

COMMENT(Used in CreateWindow for backing-store hint)

#define NotUseful               0
#define WhenMapped              1
#define Always                  2

COMMENT(Used in GetWindowAttributes reply)

#define IsUnmapped              0
#define IsUnviewable            1
#define IsViewable              2

COMMENT(Used in ChangeSaveSet)

#define SetModeInsert           0
#define SetModeDelete           1

COMMENT(Used in ChangeCloseDownMode)

#define DestroyAll              0
#define RetainPermanent         1
#define RetainTemporary         2

COMMENT(Window stacking method (in configureWindow))

#define Above                   0
#define Below                   1
#define TopIf                   2
#define BottomIf                3
#define Opposite                4

COMMENT(Circulation direction)

#define RaiseLowest             0
#define LowerHighest            1

COMMENT(Property modes)

#define PropModeReplace         0
#define PropModePrepend         1
#define PropModeAppend          2

COMMENT(graphics functions, as in GC.alu)

#define GXclear                 0x0             /* 0 */
#define GXand                   0x1             /* src AND dst */
#define GXandReverse            0x2             /* src AND NOT dst */
#define GXcopy                  0x3             /* src */
#define GXandInverted           0x4             /* NOT src AND dst */
#define GXnoop                  0x5             /* dst */
#define GXxor                   0x6             /* src XOR dst */
#define GXor                    0x7             /* src OR dst */
#define GXnor                   0x8             /* NOT src AND NOT dst */
#define GXequiv                 0x9             /* NOT src XOR dst */
#define GXinvert                0xa             /* NOT dst */
#define GXorReverse             0xb             /* src OR NOT dst */
#define GXcopyInverted          0xc             /* NOT src */
#define GXorInverted            0xd             /* NOT src OR dst */
#define GXnand                  0xe             /* NOT src OR NOT dst */
#define GXset                   0xf             /* 1 */

COMMENT(LineStyle)

#define LineSolid               0
#define LineOnOffDash           1
#define LineDoubleDash          2

COMMENT(capStyle)

#define CapNotLast              0
#define CapButt                 1
#define CapRound                2
#define CapProjecting           3

COMMENT(joinStyle)

#define JoinMiter               0
#define JoinRound               1
#define JoinBevel               2

COMMENT(fillStyle)

#define FillSolid               0
#define FillTiled               1
#define FillStippled            2
#define FillOpaqueStippled      3

COMMENT(fillRule)

#define EvenOddRule             0
#define WindingRule             1

COMMENT(subwindow mode)

#define ClipByChildren          0
#define IncludeInferiors        1

COMMENT(SetClipRectangles ordering)

#define Unsorted                0
#define YSorted                 1
#define YXSorted                2
#define YXBanded                3

COMMENT(CoordinateMode for drawing routines)

#define CoordModeOrigin         0       /* relative to the origin */
#define CoordModePrevious       1       /* relative to previous point */

COMMENT(Polygon shapes)

#define Complex                 0       /* paths may intersect */
#define Nonconvex               1       /* no paths intersect, but not convex */
#define Convex                  2       /* wholly convex */

COMMENT(Arc modes for PolyFillArc)

#define ArcChord                0       /* join endpoints of arc */
#define ArcPieSlice             1       /* join endpoints to center of arc */

COMMENT(GC components: masks used in CreateGC, CopyGC, ChangeGC, OR'ed into
GC.stateChanges)

#define GCFunction              (1L<<0)
#define GCPlaneMask             (1L<<1)
#define GCForeground            (1L<<2)
#define GCBackground            (1L<<3)
#define GCLineWidth             (1L<<4)
#define GCLineStyle             (1L<<5)
#define GCCapStyle              (1L<<6)
#define GCJoinStyle             (1L<<7)
#define GCFillStyle             (1L<<8)
#define GCFillRule              (1L<<9) 
#define GCTile                  (1L<<10)
#define GCStipple               (1L<<11)
#define GCTileStipXOrigin       (1L<<12)
#define GCTileStipYOrigin       (1L<<13)
#define GCFont                  (1L<<14)
#define GCSubwindowMode         (1L<<15)
#define GCGraphicsExposures     (1L<<16)
#define GCClipXOrigin           (1L<<17)
#define GCClipYOrigin           (1L<<18)
#define GCClipMask              (1L<<19)
#define GCDashOffset            (1L<<20)
#define GCDashList              (1L<<21)
#define GCArcMode               (1L<<22)

COMMENT(used in QueryFont -- draw direction)

#define FontLeftToRight         0
#define FontRightToLeft         1

#define FontChange              255

COMMENT(ImageFormat -- PutImage, GetImage)

#define XYBitmap                0       /* depth 1, XYFormat */
#define XYPixmap                1       /* depth == drawable depth */
#define ZPixmap                 2       /* depth == drawable depth */

COMMENT(For CreateColormap)

#define AllocNone               0       /* create map with no entries */
#define AllocAll                1       /* allocate entire map writeable */

COMMENT(Flags used in StoreNamedColor, StoreColors)

#define DoRed                   (1<<0)
#define DoGreen                 (1<<1)
#define DoBlue                  (1<<2)

COMMENT(QueryBestSize Class)

#define CursorShape             0       /* largest size that can be displayed */
#define TileShape               1       /* size tiled fastest */
#define StippleShape            2       /* size stippled fastest */

COMMENT(KEYBOARD/POINTER STUFF)

#define AutoRepeatModeOff       0
#define AutoRepeatModeOn        1
#define AutoRepeatModeDefault   2

#define LedModeOff              0
#define LedModeOn               1

COMMENT(masks for ChangeKeyboardControl)

#define KBKeyClickPercent       (1L<<0)
#define KBBellPercent           (1L<<1)
#define KBBellPitch             (1L<<2)
#define KBBellDuration          (1L<<3)
#define KBLed                   (1L<<4)
#define KBLedMode               (1L<<5)
#define KBKey                   (1L<<6)
#define KBAutoRepeatMode        (1L<<7)

#define MappingSuccess          0
#define MappingBusy             1
#define MappingFailed           2

#define MappingModifier         0
#define MappingKeyboard         1
#define MappingPointer          2

COMMENT(SCREEN SAVER STUFF)

#define DontPreferBlanking      0
#define PreferBlanking          1
#define DefaultBlanking         2

#define DisableScreenSaver      0
#define DisableScreenInterval   0

#define DontAllowExposures      0
#define AllowExposures          1
#define DefaultExposures        2

COMMENT(for ForceScreenSaver)

#define ScreenSaverReset 0
#define ScreenSaverActive 1

COMMENT(for ChangeHosts)

#define HostInsert              0
#define HostDelete              1

COMMENT(for ChangeAccessControl)

#define EnableAccess            1      
#define DisableAccess           0

COMMENT(Display classes used in opening the connection.
Note that the statically allocated ones are even numbered and the
dynamically changeable ones are odd numbered.)

#define StaticGray              0
#define GrayScale               1
#define StaticColor             2
#define PseudoColor             3
#define TrueColor               4
#define DirectColor             5

COMMENT(Byte order used in imageByteOrder and bitmapBitOrder)

#define LSBFirst                0
#define MSBFirst                1

ENDXCBGEN
