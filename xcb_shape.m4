XCBGEN(XCB_SHAPE)
_H`'INCHEADERS(INCHERE(xp_core.h))
_C`'INCHEADERS(INCHERE(xcb_shape.h))

BEGINEXTENSION(SHAPE, Shape)
HEADERONLY(`
typedef CARD8 SHAPE_OP;
typedef CARD8 SHAPE_KIND;

EVENT(ShapeNotify, 0, `
    REPLY(SHAPE_KIND, `shape_kind')
    REPLY(Window, `affected_window')
    REPLY(INT16, `extents_x')
    REPLY(INT16, `extents_y')
    REPLY(CARD16, `extents_width')
    REPLY(CARD16, `extents_height')
    REPLY(Time, `server_time')
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
    PARAM(Window, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
    LOCALPARAM(CARD32, `rectangles_len')
    LISTPARAM(xRectangle, `rectangles', `rectangles_len')
')

VOIDREQUEST(ShapeMask, `
    OPCODE(2)
    PARAM(SHAPE_OP, `operation')
    PARAM(SHAPE_KIND, `destination_kind')
    PAD(2)
    PARAM(Window, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
    PARAM(Pixmap, `source_bitmap')
')

VOIDREQUEST(ShapeCombine, `
    OPCODE(3)
    PARAM(SHAPE_OP, `operation')
    PARAM(SHAPE_KIND, `destination_kind')
    PARAM(SHAPE_KIND, `source_kind')
    PAD(1)
    PARAM(Window, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
    PARAM(Window, `source_window')
')

VOIDREQUEST(ShapeOffset, `
    OPCODE(4)
    PARAM(SHAPE_KIND, `destination_kind')
    PAD(3)
    PARAM(Window, `destination_window')
    PARAM(INT16, `x_offset')
    PARAM(INT16, `y_offset')
')

REQUEST(ShapeQueryExtents, `
    OPCODE(5)
    PARAM(Window, `destination_window')
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
    PARAM(Window, `destination_window')
    PARAM(BOOL, `enable')
')

REQUEST(ShapeInputSelected, `
    OPCODE(6)
    PARAM(Window, `destination_window')
', `
    REPLY(BOOL, `enabled')
')

REQUEST(ShapeGetRectangles, `
    OPCODE(7)
    PARAM(Window, `window')
    PARAM(SHAPE_KIND, `source_kind')
', `
    REPLY(BYTE, `ordering')
    PAD(1)
    REPLY(CARD32, `rectangles_len')
    ARRAYREPLY(xRectangle, `rectangles', `rectangles_len')
')

ENDEXTENSION
ENDXCBGEN
