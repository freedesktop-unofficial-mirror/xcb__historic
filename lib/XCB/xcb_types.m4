XCBGEN(xcb_types, `
Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')HEADERONLY(REQUIRE(X11, XCB, xcb_consts))

/* forward declaration from xcb_conn.h */
struct XCBConnection;

/* Core protocol types */

PACKETSTRUCT(Generic, `Rep')
PACKETSTRUCT(Generic, `Event')
PACKETSTRUCT(Generic, `Error')

COOKIETYPE(`Void')

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

STRUCT(DEPTH, `
    FIELD(CARD8, `depth')
    PAD(1)
    FIELD(CARD16, `visuals_len')
    PAD(4)
    ARRAYFIELD(VISUALTYPE, `visuals', `R->visuals_len')
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
    LISTFIELD(DEPTH, `allowed_depths', `R->allowed_depths_len')
')

STRUCT(XCBConnSetupReq, `
    FIELD(CARD8, `byte_order')
    PAD(1)
    FIELD(CARD16, `protocol_major_version')
    FIELD(CARD16, `protocol_minor_version')
    FIELD(CARD16, `authorization_protocol_name_len')
    FIELD(CARD16, `authorization_protocol_data_len')
    ARRAYFIELD(char, `authorization_protocol_name', `R->authorization_protocol_name_len')
    ARRAYFIELD(char, `authorization_protocol_data', `R->authorization_protocol_data_len')
')

STRUCT(XCBConnSetupGenericRep, `
    FIELD(CARD8, `status')
    PAD(5)
    FIELD(CARD16, `length')
')

STRUCT(XCBConnSetupFailedRep, `
    FIELD(CARD8, `status') dnl always 0 -> Failed
    FIELD(CARD8, `reason_len')
    FIELD(CARD16, `protocol_major_version')
    FIELD(CARD16, `protocol_minor_version')
    FIELD(CARD16, `length')
    ARRAYFIELD(char, `reason', `R->reason_len')
')

STRUCT(XCBConnSetupAuthenticateRep, `
    FIELD(CARD8, `status') dnl always 2 -> Authenticate
    PAD(5)
    FIELD(CARD16, `length')
    ARRAYFIELD(char, `reason', `R->length * 4')
')

STRUCT(XCBConnSetupSuccessRep, `
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
    ARRAYFIELD(char, `vendor', `R->vendor_len')
    ARRAYFIELD(FORMAT, `pixmap_formats', `R->pixmap_formats_len')
    LISTFIELD(SCREEN, `roots', `R->roots_len')
')

ENDXCBGEN
