XCBGEN(xcb_shm, `
Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')
BEGINEXTENSION(MIT-SHM, Shm)
XIDTYPE(SHMSEG)
HEADERONLY(`
EVENT(ShmCompletion, 0, `
    PAD(1)
    REPLY(DRAWABLE, `drawable')
    REPLY(SHMSEG, `shmseg')
    REPLY(CARD16, `minor_event')
    REPLY(BYTE, `major_event')
    PAD(1)
    REPLY(CARD32, `offset')
')

ERRORCOPY(BadShmSeg, 0, Value)
')

REQUEST(ShmQueryVersion, `
    OPCODE(0)
', `
    REPLY(BOOL, `shared_pixmaps')
    REPLY(CARD16, `major_version')
    REPLY(CARD16, `minor_version')
    REPLY(CARD16, `uid')
    REPLY(CARD16, `gid')
    REPLY(CARD8, `pixmap_format')
')

VOIDREQUEST(ShmAttach, `
    OPCODE(1)
    PARAM(SHMSEG, `shmseg')
    PARAM(CARD32, `shmid')
    PARAM(BOOL, `read_only')
')

VOIDREQUEST(ShmDetach, `
    OPCODE(2)
    PARAM(SHMSEG, `shmseg')
')

VOIDREQUEST(ShmPutImage, `
    OPCODE(3)
    PARAM(DRAWABLE, `drawable')
    PARAM(GCONTEXT, `gc')
    PARAM(CARD16, `total_width')
    PARAM(CARD16, `total_height')
    PARAM(CARD16, `src_x')
    PARAM(CARD16, `src_y')
    PARAM(CARD16, `src_width')
    PARAM(CARD16, `src_height')
    PARAM(INT16, `dst_x')
    PARAM(INT16, `dst_y')
    PARAM(CARD8, `depth')
    PARAM(CARD8, `format')
    PARAM(CARD8, `send_event')
    PAD(1)
    PARAM(SHMSEG, `shmseg')
    PARAM(CARD32, `offset')
')

REQUEST(ShmGetImage, `
    OPCODE(4)
    PARAM(DRAWABLE, `drawable')
    PARAM(INT16, `x')
    PARAM(INT16, `y')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD32, `plane_mask')
    PARAM(CARD8, `format')
    PAD(3)
    PARAM(SHMSEG, `shmseg')
    PARAM(CARD32, `offset')
', `
    REPLY(CARD8, `depth')
    REPLY(VISUALID, `visual')
    REPLY(CARD32, `size')
')

VOIDREQUEST(ShmCreatePixmap, `
    OPCODE(5)
    PARAM(PIXMAP, `pid')
    PARAM(DRAWABLE, `drawable')
    PARAM(CARD16, `width')
    PARAM(CARD16, `height')
    PARAM(CARD8, `depth')
    PAD(3)
    PARAM(SHMSEG, `shmseg')
    PARAM(CARD32, `offset')
')

ENDEXTENSION
ENDXCBGEN
