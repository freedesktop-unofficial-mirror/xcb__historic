XCBGEN(xcb_render,`
Copyright (C) 2001-2002 Bart Massey, Jamey Sharp, and Andy Howe.
All Rights Reserved.  See the file COPYING in this directory for 
licensing information.')
BEGINEXTENSION(RENDER,Render)


dnl NOT IMPLEMENTED:
dnl RenderTrapezoids (no reply)
dnl RenderQueryDither
dnl RenderTrStrip (no reply)
dnl RenderTriFan (no reply)
dnl RenderColorTrapezoids (no reply)
dnl RenderColorTriangles (no reply)
dnl RenderTransform (no reply)
dnl RenderAddGlyphsFromPicture (no reply)

dnl The following are the structures used by render
XIDTYPE(PICTURE)

XIDTYPE(PICTFORMAT)

XIDTYPE(GLYPHSET)


dnl FIXME:
dnl I'm not sure how to handle the "Fixed" type.
dnl Should I make a structure with a 24 bit part and an 8 bit part?
dnl Should I just use a CARD32? Should I use something else?
dnl typedef INT32                   FIXED

COMMENT(PictType modes)
#define PictTypeIndexed         0
#define PictTypeDirect          1

COMMENT(PictOp modes)
#define PictOpClear             0
#define PictOpSrc               1
#define PictOpDst               2
#define PictOpOver              3
#define PictOpOverReverse       4
#define PictOpIn                5
#define PictOpInReverse         6
#define PictOpOut               7
#define PictOpOutReverse        8
#define PictOpAtop              9
#define PictOpAtopReverse       10
#define PictOpXor               11
#define PictOpAdd               12
#define PictOpSaturate          13

STRUCT(XCBRenderColor, `
    FIELD(CARD16, `red')
    FIELD(CARD16, `green')
    FIELD(CARD16, `blue')
    FIELD(CARD16, `alpha')
')

COMMENT(There is no ChannelMask structure. Just use one CARD16
for the shift, and one CARD16 for the mask where ever there
is supposed to be a ChannelMask type.)

STRUCT(XCBRenderDirectFormat, `
    FIELD(CARD16, `redShift')
    FIELD(CARD16, `redMask')
    FIELD(CARD16, `greenShift')
    FIELD(CARD16, `greenMask')
    FIELD(CARD16, `blueShift')
    FIELD(CARD16, `blueMask')
    FIELD(CARD16, `alphaShift')
    FIELD(CARD16, `alphaMask')
')

dnl STRUCT(XCBRenderPictFormInfo, `
dnl     FIELD(PICTFORMAT, `id')
dnl     FIELD(CARD8, `type')
dnl     FIELD(CARD8, `depth')
dnl     PAD(2)
dnl    FIELD(XCBRenderDirectFormat, `direct')
dnl    FIELD(COLORMAP, `colormap')
dnl ')

dnl RenderQueryVersion, opcode 0
REQUEST(RenderQueryVersion, `
    OPCODE(0)
    PARAM(CARD32, `majorVersion')
    PARAM(CARD32, `minorVersion')
', `
    PAD(1)
    REPLY(CARD32, `majorVersion')
    REPLY(CARD32, `minorVersion')
    PAD(16)
')

dnl RenderQueryPictFormats, opcode 1
REQUEST(RenderQueryPictFormats, `
    OPCODE(1)
', `
    PAD(1)
    REPLY(CARD32, `numFormats')
    REPLY(CARD32, `numScreens')
    REPLY(CARD32, `numDepths')
    REPLY(CARD32, `numVisuals')
    PAD(8)
    dnl I know, this is bad, it should probably be changed.
    dnl Specifically, the last argument should probably be
    dnl other than zero
    dnl ARRAYREPLY(CARD8, `formats', `0') 
    dnl LISTREPLY(RenderPictFormInfo, `formats')
    dnl LISTREPLY(RenderPictScreen, `screens')
')

dnl RenderQueryPictIndexValues, opcode 2
dnl REQUEST(RenderQueryPictIndexValues, `
dnl     OPCODE(2)
dnl     PARAM(CARD32
dnl ', `
dnl ')

dnl RenderCreatePicture, opcode 4
VOIDREQUEST(RenderCreatePicture, `
    OPCODE(4)
    PARAM(PICTURE, `picture')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')


dnl RenderChangePicture (no reply), opcode 5
VOIDREQUEST(RenderChangePicture, `
    OPCODE(5)
    PARAM(PICTURE, `picture')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')


dnl RenderSetPictureClipRectangles (no reply), opcode 6
dnl VOIDREQUEST(RenderSetClipRectangles, `
dnl     OPCODE(6)
dnl     PARAM(PICTURE, `picture')
dnl     PARAM(CARD16, `xOrigin')
dnl    PARAM(CARD16, `yOrigin')
    


dnl RenderFreePicture (no reply), opcode 7
VOIDREQUEST(RenderFreePicture, `
    OPCODE(7)
    PARAM(PICTURE, `picture')
')


dnl RenderComposite (no reply), opcode 8
VOIDREQUEST(RenderComposite, `
    OPCODE(8)
    PARAM(CARD8, `op')
    PAD(3)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `mask')
    PARAM(PICTURE, `dst')
    PARAM(INT16, `xSrc')
    PARAM(INT16, `ySrc')
    PARAM(INT16, `xMask')
    PARAM(INT16, `yMask')
    PARAM(INT16, `xDst')
    PARAM(INT16, `yDst')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')


dnl RenderScale (no reply), opcode 9
dnl RenderTriangles (no reply), opcode 11
dnl RenderCreateGlyphSet (no reply), opcode 17
dnl RenderReferenceGlyphSet (no reply), opcode 18
dnl RenderFreeGlyphSet (no reply), opcode 19
dnl RenderAddGlyphs (no reply), opcode 20
dnl RenderFreeGlyphs (no reply), opcode 22
dnl RenderCompositeGlyphs8, opcode 23
dnl RenderCompositeGlyphs16, opcode 24
dnl RenderCompositeGlyphs32, opcode 25
dnl RenderFillRectangles, opcode 26 

ENDEXTENSION
ENDXCBGEN
