XCBGEN(xcb_shape, `
Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')
BEGINEXTENSION(SHAPE, Shape)
HEADERONLY(`
typedef CARD8 SHAPE_OP;
typedef CARD8 SHAPE_KIND;

EVENT(ShapeNotify, 0, `
    REPLY(SHAPE_KIND, `shape_kind')
    REPLY(WINDOW, `affected_window')
    REPLY(INT16, `extents_x')
    REPLY(INT16, `extents_y')
    REPLY(CARD16, `extents_width')
    REPLY(CARD16, `extents_height')
    REPLY(TIMESTAMP, `server_time')
    REPLY(BOOL, `shaped')
')
')
REQUEST(ShapeQueryVersion, `
    OPCODE(0)
', `
    PAD(1)
    REPLY(CARD16, `major_version')
    REPLY(CARD16, `minor_version')
')

VOIDREQUEST(ShapeRectangles, `
    OPCODE(1)
    PARAM(SHAPE_OP, `operation')
    PARAM(SHAPE_KIND, `destination_kind')
    PARAM(BYTE, `ordering')
    PAD(1)
    PARAM(WINDOW, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
    LOCALPARAM(CARD32, `rectangles_len')
    LISTPARAM(RECTANGLE, `rectangles', `rectangles_len')
')

VOIDREQUEST(ShapeMask, `
    OPCODE(2)
    PARAM(SHAPE_OP, `operation')
    PARAM(SHAPE_KIND, `destination_kind')
    PAD(2)
    PARAM(WINDOW, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
    PARAM(PIXMAP, `source_bitmap')
')

VOIDREQUEST(ShapeCombine, `
    OPCODE(3)
    PARAM(SHAPE_OP, `operation')
    PARAM(SHAPE_KIND, `destination_kind')
    PARAM(SHAPE_KIND, `source_kind')
    PAD(1)
    PARAM(WINDOW, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
    PARAM(WINDOW, `source_window')
')

VOIDREQUEST(ShapeOffset, `
    OPCODE(4)
    PARAM(SHAPE_KIND, `destination_kind')
    PAD(3)
    PARAM(WINDOW, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
')

REQUEST(ShapeQueryExtents, `
    OPCODE(5)
    PARAM(WINDOW, `destination_window')
', `
    PAD(1)
    REPLY(BOOL, `bounding_shaped')
    REPLY(BOOL, `clip_shaped')
    PAD(2)
    REPLY(INT16, `bounding_shape_extents_x')
    REPLY(INT16, `bounding_shape_extents_y')
    REPLY(CARD16, `bounding_shape_extents_width')
    REPLY(CARD16, `bounding_shape_extents_height')
    REPLY(INT16, `clip_shape_extents_x')
    REPLY(INT16, `clip_shape_extents_y')
    REPLY(CARD16, `clip_shape_extents_width')
    REPLY(CARD16, `clip_shape_extents_height')
')

VOIDREQUEST(ShapeSelectInput, `
    OPCODE(6)
    PARAM(WINDOW, `destination_window')
    PARAM(BOOL, `enable')
')

REQUEST(ShapeInputSelected, `
    OPCODE(6)
    PARAM(WINDOW, `destination_window')
', `
    REPLY(BOOL, `enabled')
')

REQUEST(ShapeGetRectangles, `
    OPCODE(7)
    PARAM(WINDOW, `window')
    PARAM(SHAPE_KIND, `source_kind')
', `
    REPLY(BYTE, `ordering')
    PAD(1)
    REPLY(CARD32, `rectangles_len')
    ARRAYREPLY(RECTANGLE, `rectangles', `R->rectangles_len')
')

ENDEXTENSION
ENDXCBGEN
