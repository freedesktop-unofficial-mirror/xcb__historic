XCBGEN(xcb_render, `
Copyright (C) 2002 Carl D. Worth
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')
BEGINEXTENSION(RENDER, Render)


XIDTYPE(PICTURE)
XIDTYPE(PICTFORMAT)
XIDTYPE(GLYPHSET)

HEADERONLY(`
typedef INT32 FIXED;
typedef CARD32 GLYPH;

#define make_fixed(i,f) (FIXED)((i) << 16) | ((f) & 0xffff)

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
') 

STRUCT(COLOR, `
    FIELD(CARD16, `red')
    FIELD(CARD16, `green')
    FIELD(CARD16, `blue')
    FIELD(CARD16, `alpha')
')

/* XXX: CHANNELMASK */

STRUCT(DIRECTFORMAT, `
    FIELD(CARD16, `red_shift')
    FIELD(CARD16, `red_mask')
    FIELD(CARD16, `green_shift')
    FIELD(CARD16, `green_mask')
    FIELD(CARD16, `blue_shift')
    FIELD(CARD16, `blue_mask')
    FIELD(CARD16, `alpha_shift')
    FIELD(CARD16, `alpha_mask')
')

STRUCT(PICTFORMINFO, `
    FIELD(PICTFORMAT, `id')
    FIELD(CARD8, `type')
    FIELD(CARD8, `depth')
    PAD(2)
    FIELD(DIRECTFORMAT, `direct')
    FIELD(COLORMAP, `colormap')
')

/* XXX: INDEXVALUE */

STRUCT(PICTVISUAL, `
    FIELD(VISUALID, `visual')
    FIELD(PICTFORMAT, `format')
')

STRUCT(PICTDEPTH, `
    FIELD(CARD8, `depth')
    PAD(1)
    FIELD(CARD16, `num_visuals')
    PAD(4)
    LISTFIELD(PICTVISUAL, `visuals', `R->num_visuals')
')

STRUCT(PICTSCREEN, `
    FIELD(CARD32, `num_depths')
    FIELD(PICTFORMAT, `fallback')
    LISTFIELD(PICTDEPTH, `depths', `R->num_depths')
')


/* XXX: DITHERINFO */


STRUCT(POINTFIX, `
    FIELD(FIXED, `x')
    FIELD(FIXED, `y')
')

/* XXX: POLYEDGE */
/* XXX: POLYMODE */
/* XXX: COLORPOINT */
/* XXX: SPANFIX */
/* XXX: COLORSPANFIX */
/* XXX: QUAD */

STRUCT(TRIANGLE, `
    FIELD(POINTFIX, `p1')
    FIELD(POINTFIX, `p2')
    FIELD(POINTFIX, `p3')
')

STRUCT(LINEFIXED, `
    FIELD(POINTFIX, `p1')
    FIELD(POINTFIX, `p2')
')

STRUCT(TRAP, `
    FIELD(FIXED, `top')
    FIELD(FIXED, `bottom')
    FIELD(LINEFIXED, `left')
    FIELD(LINEFIXED, `right')
')

/* XXX: COLORTRIANGLE */
/* XXX: COLORTRAP */



STRUCT(GLYPHINFO, `
    FIELD(CARD16, `width')
    FIELD(CARD16, `height')
    FIELD(CARD16, `x')
    FIELD(CARD16, `y')
    FIELD(CARD16, `x_off')
    FIELD(CARD16, `y_off')
')

/* XXX: PICTGLYPH */

UNION(GLYPHABLE, `
    FIELD(GLYPHSET, `glyphset')
    FIELD(FONTABLE, `fontable')
')

STRUCT(GLYPHELT8, `
    FIELD(INT16, `dx')
    FIELD(INT16, `dy')
    dnl LISTFIELD(CARD8, `glyphs', `R->glyphs_len')
')

UNION(GLYPHITEM8, `
    FIELD(GLYPHELT8, `glyphelt8')
    FIELD(GLYPHABLE, `glyphable')
')

STRUCT(GLYPHELT16, `
    FIELD(INT16, `dx')
    FIELD(INT16, `dy')
    dnl LISTFIELD(CARD16, `glyphs', `R->glyphs_len')
')

UNION(GLYPHITEM16, `
    FIELD(GLYPHELT16, `glyphelt8')
    FIELD(GLYPHABLE, `glyphable')
')

STRUCT(GLYPHELT32, `
    FIELD(INT16, `dx')
    FIELD(INT16, `dy')
    dnl LISTFIELD(CARD32, `glyphs', `R->glyphs_len')
')

UNION(GLYPHITEM32, `
    FIELD(GLYPHELT32, `glyphelt8')
    FIELD(GLYPHABLE, `glyphable')
')


dnl ---------------------------------------------
dnl function definitions
dnl ---------------------------------------------

REQUEST(RenderQueryVersion, `
    OPCODE(0)
    PARAM(CARD32, `client_major_version')
    PARAM(CARD32, `client_minor_version')
', `
    PAD(1)
    REPLY(CARD32, `major_version')
    REPLY(CARD32, `minor_version')
    PAD(16)
')

REQUEST(RenderQueryPictFormats, `
    OPCODE(1)
', `
    PAD(1)
    REPLY(CARD32, `num_formats')
    REPLY(CARD32, `num_screens')
    REPLY(CARD32, `num_depths')
    REPLY(CARD32, `num_visuals')
    PAD(8)
    LISTFIELD(PICTFORMINFO, `formats', `R->num_formats')
    LISTFIELD(PICTSCREEN, `screens', `R->num_screens')
')

dnl /* howea: this one needs work */
dnl REQUEST(RenderQueryPictIndexValues, `
dnl     OPCODE(2)
dnl     PARAM(PICTFORMAT, `format')
dnl ', `
dnl     PAD(1)
dnl     LISTFIELD(INDEXVALUE, `values')
dnl ')

dnl /* howea: this one needs work */
dnl REQUEST(RenderQueryDithers, `
dnl     OPCODE(3)
dnl     PARAM(DRAWABLE, `drawable')
dnl ', `
dnl     LISTFIELD(DITHERINFO, `dithers')
dnl ')
dnl */

VOIDREQUEST(RenderCreatePicture, `
    OPCODE(4)
    PARAM(PICTURE, `pid')
    PARAM(DRAWABLE, `drawable')
    PARAM(PICTFORMAT, `format')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(RenderChangePicture, `
    OPCODE(5)
    PARAM(PICTURE, `pid')
    VALUEPARAM(CARD32, `value_mask', `value_list')
')

VOIDREQUEST(RenderSetPictureClipRectangles, `
    OPCODE(6)
    PARAM(PICTURE, `picture')
    PARAM(INT16, `clip_x_origin')
    PARAM(INT16, `clip_y_origin')
    LOCALPARAM(CARD16, `rects_len')
    LISTPARAM(RECTANGLE, `rects', `rects_len')
')

VOIDREQUEST(RenderFreePicture, `
    OPCODE(7)
    PARAM(PICTURE, `pid')
')

VOIDREQUEST(RenderComposite, `
    OPCODE(8)
    PARAM(CARD8, `op')
    PAD(3)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `mask')
    PARAM(PICTURE, `dst')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `mask_x')
    PARAM(INT16, `mask_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(RenderScale, `
    OPCODE(9)
    PARAM(CARD32, `color_scale')
    PARAM(CARD32, `alpha_scale')
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
')

VOIDREQUEST(RenderTrapezoids, `
    OPCODE(10)
    PARAM(CARD8, `op')
    PAD(3)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(PICTFORMAT, `mask_format')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    LOCALPARAM(CARD16, `traps_len')
    LISTPARAM(TRAP, `traps', `traps_len')
')

VOIDREQUEST(RenderTriangles, `
    OPCODE(11)
    PARAM(CARD8, `op')
    PAD(3)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(PICTFORMAT, `mask_format')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    LOCALPARAM(CARD16, `triangles_len')
    LISTPARAM(TRIANGLE, `triangles', `triangles_len')
')

VOIDREQUEST(RenderTriStrip, `
    OPCODE(12)
    PARAM(CARD8, `op')
    PAD(3)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(PICTFORMAT, `mask_format')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(POINTFIX, `points', `points_len')
')

VOIDREQUEST(RenderTriFan, `
    OPCODE(13)
    PARAM(CARD8, `op')
    PAD(3)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(PICTFORMAT, `mask_format')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    LOCALPARAM(CARD16, `points_len')
    LISTPARAM(POINTFIX, `points', `points_len')
')

/* XXX: Don't see RenderColorTrapezoids in renderproto.h
VOIDREQUEST(RenderColorTrapezoids, `
    OPCODE(14)
    PARAM(CARD8, `op')
    PARAM(PICTURE, `dst')
    LOCALPARAM(CARD16, `traps_len')
    LISTPARAM(COLORTRAP, `traps', `traps_len')
')
*/

/* XXX: Don't see RenderColorTriangles in renderproto.h
VOIDREQUEST(RenderColorTriangles, `
    OPCODE(15)
    PARAM(CARD8, `op')
    PARAM(PICTURE, `dst')
    LOCALPARAM(CARD16, `triangles_len')
    LISTPARAM(COLORTRIANGLE, `triangles', `triangles_len')
')
*/

/* XXX: Don't see RenderTransform in renderproto.h
VOIDREQUEST(RenderTransform, `
    OPCODE(16)
    PARAM(CARD8, `op')
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(QUAD, `src_quad')
    PARAM(QUAD, `dst_quad')
    PARAM(???, `filter')
')
*/

VOIDREQUEST(RenderCreateGlyphSet, `
    OPCODE(17)
    PARAM(GLYPHSET, `gsid')
    PARAM(PICTFORMAT, `format')
')

VOIDREQUEST(RenderReferenceGlyphSet, `
    OPCODE(18)
    PARAM(GLYPHSET, `gsid')
    PARAM(GLYPHSET, `existing')
')

VOIDREQUEST(RenderFreeGlyphSet, `
    OPCODE(19)
    PARAM(GLYPHSET, `gsid')
')

VOIDREQUEST(RenderAddGlyphs, `
    OPCODE(20)
    PARAM(GLYPHSET, `glyphset')
    PARAM(CARD32, `nglyphs')
    LISTPARAM(CARD32, `glyphids', `nglyphs')
    LISTPARAM(GLYPHINFO, `glyphs', `nglyphs')
    LOCALPARAM(CARD16, `data_len')
    LISTPARAM(BYTE, `data', `data_len')
')

/* XXX: I don't see RenderAddGlyphsFromPIcture in renderproto.h
VOIDREQUEST(RenderAddGlyphsFromPicture, `
    OPCODE(21)
    PARAM(GLYPHSET, `glyphset')
    PARAM(PICTURE, `src')
    LISTPARAM(PICTGLYPH, `glyphs')
')
*/

VOIDREQUEST(RenderFreeGlyphs, `
    OPCODE(22)
    PARAM(GLYPHSET, `glyphset')
    LOCALPARAM(CARD16, `glyphs_len')
    LISTPARAM(GLYPH, `glyphs', `glyphs_len')
')

VOIDREQUEST(RenderCompositeGlyphs8, `
    OPCODE(23)
    PARAM(CARD8, `op')
    PAD(1)
    PAD(2)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(PICTFORMAT, `mask_format')
    PARAM(GLYPHABLE, `glyphset')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    LOCALPARAM(CARD16, `glyphcmds_len')
    LISTPARAM(GLYPHITEM8, `glyphcmds', `glyphcmds_len')
')

VOIDREQUEST(RenderCompositeGlyphs16, `
    OPCODE(24)
    PARAM(CARD8, `op')
    PAD(1)
    PAD(2)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(PICTFORMAT, `mask_format')
    PARAM(GLYPHABLE, `glyphset')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    LOCALPARAM(CARD16, `glyphcmds_len')
    LISTPARAM(GLYPHITEM16, `glyphcmds', `glyphcmds_len')
')

VOIDREQUEST(RenderCompositeGlyphs32, `
    OPCODE(25)
    PARAM(CARD8, `op')
    PAD(1)
    PAD(2)
    PARAM(PICTURE, `src')
    PARAM(PICTURE, `dst')
    PARAM(PICTFORMAT, `mask_format')
    PARAM(GLYPHABLE, `glyphset')
    PARAM(INT16, `src_x')
    PARAM(INT16, `src_y')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    LOCALPARAM(CARD16, `glyphcmds_len')
    LISTPARAM(GLYPHITEM32, `glyphcmds', `glyphcmds_len')
')

VOIDREQUEST(RenderFillRectangles, `
    OPCODE(26)
    PARAM(CARD8, `op')
    PAD(3)
    PARAM(PICTURE, `dst')
    PARAM(COLOR, `color')
    LOCALPARAM(CARD16, `rects_len')
    LISTPARAM(RECTANGLE, `rects', `rects_len')
')

ENDEXTENSION
ENDXCBGEN