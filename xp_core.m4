_H`'#define XP_PAD(E) ((4-((E)%4))%4)
_H
TYPE(unsigned char,XP_CARD8)
TYPE(unsigned short,XP_CARD16)
TYPE(unsigned int,XP_CARD32)
TYPE(signed char,XP_INT8)
TYPE(signed short,XP_INT16)
TYPE(signed int,XP_INT32)
TYPE(XP_CARD8,XP_BYTE)
TYPE(XP_CARD8,XP_BOOL)
_H
TYPE(XP_CARD32,XP_WINDOW)
TYPE(XP_CARD32,XP_PIXMAP)
TYPE(XP_CARD32,XP_CURSOR)
TYPE(XP_CARD32,XP_FONT)
TYPE(XP_CARD32,XP_GCONTEXT)
TYPE(XP_CARD32,XP_COLORMAP)
TYPE(XP_CARD32,XP_DRAWABLE) dnl WINDOW or PIXMAP
TYPE(XP_CARD32,XP_FONTABLE) dnl FONT or GCONTEXT
TYPE(XP_CARD32,XP_ATOM)
TYPE(XP_CARD32,XP_VISUALID)
TYPE(XP_CARD32,XP_TIMESTAMP)
TYPE(XP_CARD32,XP_KEYSYM)
TYPE(XP_CARD8,XP_KEYCODE)
TYPE(XP_CARD8,XP_BUTTON)
_H
TYPE(XP_CARD32,XP_SETofEVENT)
TYPE(XP_CARD32,XP_SETofPOINTEREVENT)
TYPE(XP_CARD32,XP_SETofDEVICEEVENT)
TYPE(XP_CARD16,XP_SETofKEYBUTMASK)
TYPE(XP_CARD16,XP_SETofKEYMASK)
_H
STRUCT(XP_FORMAT, `
FIELD(XP_CARD8,depth)
FIELD(XP_CARD8,bits_per_pixel)
FIELD(XP_CARD8,scanline_pad)
PAD(5)
')
_H
STRUCT(XP_VISUALTYPE, `
FIELD(XP_VISUALID, `visual_id')
FIELD(XP_CARD8, `class')
FIELD(XP_CARD8, `bits_per_rgb_value')
FIELD(XP_CARD16, `colormap_entries')
FIELD(XP_CARD32, `red_mask')
FIELD(XP_CARD32, `green_mask')
FIELD(XP_CARD32, `blue_mask')
PAD(4)
')
_H
dnl XP_DEPTH is special, and has its own list-handling for visuals.
dnl XP_DEPTH is only used during connection set-up, by XCB_Connect.
STRUCT(XP_DEPTH, `
FIELD(XP_CARD8, `depth')
PAD(1)
FIELD(XP_CARD16, `visuals_length')
PAD(4)
POINTERFIELD(XP_VISUALTYPE, `visuals')
')
_H
dnl XP_SCREEN is special, and has its own list-handling for allowed_depths.
dnl XP_SCREEN is only used during connection set-up, by XCB_Connect.
STRUCT(XP_SCREEN, `
FIELD(XP_WINDOW,root)
FIELD(XP_COLORMAP,default_colormap)
FIELD(XP_CARD32,white_pixel)
FIELD(XP_CARD32,black_pixel)
FIELD(XP_SETofEVENT,current_input_masks)
FIELD(XP_CARD16,width_in_pixels)
FIELD(XP_CARD16,height_in_pixels)
FIELD(XP_CARD16,width_in_millimeters)
FIELD(XP_CARD16,height_in_millimeters)
FIELD(XP_CARD16,min_installed_maps)
FIELD(XP_CARD16,max_installed_maps)
FIELD(XP_VISUALID,root_visual)
dnl 0 = Never, 1 = WhenMapped, 2 = Always
FIELD(XP_CARD8,backing_stores)
FIELD(XP_BOOL,save_unders)
FIELD(XP_CARD8,root_depth)
dnl always a multiple of 4
FIELD(XP_CARD8,allowed_depths_length)
POINTERFIELD(XP_DEPTH,allowed_depths)
')
_H
define(`_BASESTRUCT',1)dnl
COOKIETYPE(`void')
_H
STRUCT(XCB_Resp_Data, `
FIELD(pthread_mutex_t, `pending')
FIELD(int, `received')
FIELD(int, `seqnum')
POINTERFIELD(void, `data')
POINTERFIELD(struct XCB_Resp_Data, `next')
')
_H
STRUCT(XCB_Display_Info, `
FIELD(XP_CARD16, `protocol_major_version')
FIELD(XP_CARD16, `protocol_minor_version')
POINTERFIELD(char, `vendor')
FIELD(XP_CARD32, `release_number')
FIELD(XP_CARD32, `resource_id_base')
FIELD(XP_CARD32, `resource_id_mask')
FIELD(XP_CARD32, `motion_buffer_size')
FIELD(XP_CARD16, `maximum_request_length')
FIELD(XP_CARD8, `image_byte_order')
FIELD(XP_CARD8, `bitmap_format_bit_order')
FIELD(XP_CARD8, `bitmap_format_scanline_unit')
FIELD(XP_CARD8, `bitmap_format_scanline_pad')
FIELD(XP_CARD8, `min_keycode')
FIELD(XP_CARD8, `max_keycode')
FIELD(XP_CARD8, `pixmap_formats_length')
POINTERFIELD(XP_FORMAT, `pixmap_formats')
FIELD(XP_CARD8, `roots_length')
POINTERFIELD(XP_SCREEN, `roots')
')
_H
STRUCT(XCB_Connection, `
FIELD(int, `fd')
FIELD(pthread_mutex_t, `locked')
FIELD(int, `seqnum')
ARRAYFIELD(XP_CARD8, `outqueue', 4096)
FIELD(int, `n_outqueue')
POINTERFIELD(XCB_Resp_Data, `resp_data_head')
POINTERFIELD(XCB_Resp_Data, `resp_data_tail')
dnl FIELD(XCB_Atom_Dictionary, `atoms')
FIELD(XCB_Display_Info, `disp_info')
')
define(`_BASESTRUCT',0)dnl
_H
FUNCTION(`', `int XCB_Connection_Lock', `XCB_Connection *c', `
    return pthread_mutex_lock(&c->locked);
')
_C
FUNCTION(`', `int XCB_Connection_Unlock', `XCB_Connection *c', `
    return pthread_mutex_unlock(&c->locked);
')
_C
FUNCTION(`', `int XCB_Read', dnl
`XCB_Connection *c, unsigned char *buf, int len', `
    /* buffering here might be a win later */
    return read(c->fd, buf, len);
')

/* PRE: c is locked */
/* POST: c's queue has been flushed */
FUNCTION(`', `int XCB_Flush', `XCB_Connection *c', `
    write(c->fd, c->outqueue, c->n_outqueue);
    c->n_outqueue = 0;
    return 1;
')

/* PRE: c is locked, buf points to valid memory, and len contains the number
        of valid characters in buf */
/* POST: if the queue would have overflowed, it has been written first;
         if buf's contents are larger than the queue, buf has been written;
         otherwise, buf has been copied into the queue. */
FUNCTION(`', `int XCB_Write', dnl
`XCB_Connection *c, unsigned char *buf, int len', `
    if(c->n_outqueue + len >= sizeof(c->outqueue))
    {
        XCB_Flush(c);
        if(len >= sizeof(c->outqueue))
        {
            write(c->fd, buf, len);
            goto done;
        }
    }

    memcpy(c->outqueue + c->n_outqueue, buf, len);
    c->n_outqueue += len;
done:
    return ++c->seqnum;
')

/* PRE: c is locked and cur points to valid memory */
/* POST: cur is in the list */
FUNCTION(`', `int XCB_Add_Resp_Data', dnl
`XCB_Connection *c, XCB_Resp_Data *cur', `
    assert(cur);
    cur->next = 0;
    if(c->resp_data_tail)
        c->resp_data_tail->next = cur;
    else
        c->resp_data_head = cur;

    c->resp_data_tail = cur;
    return 1;
')

/* PRE: c is locked and cur points to valid memory */
/* POST: *cur points at the desired data or is 0; if prev was not 0,
         (*prev)->next points at the desired data or *prev is 0 */
FUNCTION(`', `int XCB_Find_Resp_Data', dnl
`XCB_Connection *c, int seqnum, XCB_Resp_Data **cur, XCB_Resp_Data **prev', `
    assert(cur);
    if(prev)
        *prev = 0;
    *cur = c->resp_data_head;
    while(*cur)
    {
        if((*cur)->seqnum == seqnum)
            break;
        if(prev)
            *prev = *cur;
        *cur = (*cur)->next;
    }
    return 1;
')

/* PRE: c is locked, cur points to valid memory, and prev points to the
        immediate predecessor to cur or is 0 if cur is the first item in
        the list */
/* POST: cur is no longer in the list (but the caller has to free it) */
FUNCTION(`', `int XCB_Remove_Resp_Data', dnl
`XCB_Connection *c, XCB_Resp_Data *cur, XCB_Resp_Data *prev', `
    assert(cur);
    assert(prev ? prev->next == cur : c->resp_data_head == cur);

    if(prev)
        prev->next = cur->next;
    else
        c->resp_data_head = cur->next;

    if(!cur->next)
        c->resp_data_tail = prev;

    return 1;
')

FUNCTION(`', `int XCB_Open', `const char *display', `
    /* TODO: write this */
    return -1;
')
_C
FUNCTION(`', `int XCB_Open_TCP', `const char *host, unsigned short port', `
    int fd;
    struct sockaddr_in addr = { AF_INET, htons(port) };
    /* CHECKME: never free return value of gethostbyname, right? */
    struct hostent *hostaddr = gethostbyname(host);
    assert(hostaddr);
    memcpy(&addr.sin_addr, hostaddr->h_addr_list[0], sizeof(addr.sin_addr));

    fd = socket(PF_INET, SOCK_STREAM, 0);
    assert(fd != -1);
    if(connect(fd, (struct sockaddr *) &addr, sizeof(addr)) == -1)
        return -1;
    return fd;
')
_C
FUNCTION(`', `int XCB_Open_Unix', `const char *file', `
    int fd;
    struct sockaddr_un addr = { AF_UNIX };
    strcpy(addr.sun_path, file);

    fd = socket(PF_UNIX, SOCK_STREAM, 0);
    assert(fd != -1);
    if(connect(fd, (struct sockaddr *) &addr, sizeof(addr)) == -1)
        return -1;
    return fd;
')
_C
define(`_outdiv',0)dnl
FUNCTION(`', `XCB_Connection *XCB_Connect', `int fd', `
dnl using calloc to make gdb use less painful
    XCB_Connection* c = (XCB_Connection*) calloc(1, sizeof(XCB_Connection));
    int i, j, k, vendor_length, additional_data_length;
    unsigned char *tmp, *buf;
    assert(c);

    c->fd = fd;
    pthread_mutex_init(&c->locked, 0);
    c->n_outqueue = 0;
    c->resp_data_head = 0;
    c->resp_data_tail = 0;

    /* Write the connection setup request. */
pushdef(`_divnum',divnum)divert(1)define(`_index',0)define(`_SIZE',0)dnl
    /* B = 0x42 = MSB first, l = 0x6c = LSB first */
PACK(XP_CARD8,0x42)
PAD(1)dnl
    /* This is protocol version 11.0 */
PACK(XP_CARD16,11)
PACK(XP_CARD16,0)
    /* Auth protocol name and data are both zero-length */
PACK(XP_CARD16,0)
PACK(XP_CARD16,0)
PAD(2)dnl
dnl    LISTFIELD(XP_CARD8,authorization_protocol_name,dnl
dnl       XP_PAD(authorization_protocol_name_length))
dnl    LISTFIELD(XP_CARD8,authorization_protocol_data,dnl
dnl       XP_PAD(authorization_protocol_data_length))
divert(_divnum)popdef(`_divnum')dnl
ALLOC(unsigned char, buf, _SIZE)
undivert(1)dnl
    write(c->fd, buf, _SIZE);

    /* Read the server response */
    read(c->fd, buf, 1);
    /* 0 = failed, 2 = authenticate, 1 = success */
    switch(buf[0])
    {
    case 0: /* failed */
    case 2: /* authenticate */
        return 0; /* aw, screw you. */
    }

pushdef(`_divnum',divnum)divert(1)define(`_index',0)define(`_SIZE',0)dnl
PAD(1)dnl
UNPACK(XP_CARD16, `c->disp_info.protocol_major_version')
UNPACK(XP_CARD16, `c->disp_info.protocol_minor_version')
UNPACK(XP_CARD16, `additional_data_length')
divert(_divnum)popdef(`_divnum')dnl
dnl assume this _SIZE is smaller than previous _SIZE to avoid a realloc
    read(c->fd, buf, _SIZE);
undivert(1)dnl

REALLOC(unsigned char, buf, additional_data_length * 4)
    read(c->fd, buf, additional_data_length * 4);
define(`_index',0)define(`_SIZE',0)dnl
UNPACK(XP_CARD32, `c->disp_info.release_number')
UNPACK(XP_CARD32, `c->disp_info.resource_id_base')
UNPACK(XP_CARD32, `c->disp_info.resource_id_mask')
UNPACK(XP_CARD32, `c->disp_info.motion_buffer_size')
UNPACK(XP_CARD16, `vendor_length')
UNPACK(XP_CARD16, `c->disp_info.maximum_request_length')
UNPACK(XP_CARD8, `c->disp_info.roots_length')
UNPACK(XP_CARD8, `c->disp_info.pixmap_formats_length')
dnl 0 = LSBFirst, 1 = MSBFirst
UNPACK(XP_CARD8, `c->disp_info.image_byte_order')
dnl 0 = LeastSignificant, 1 = MostSignificant
UNPACK(XP_CARD8, `c->disp_info.bitmap_format_bit_order')
UNPACK(XP_CARD8, `c->disp_info.bitmap_format_scanline_unit')
UNPACK(XP_CARD8, `c->disp_info.bitmap_format_scanline_pad')
UNPACK(XP_CARD8, `c->disp_info.min_keycode')
UNPACK(XP_CARD8, `c->disp_info.max_keycode')
PAD(4)dnl

    tmp = buf;
    buf += _index;
ALLOC(char, c->disp_info.vendor, vendor_length + 1)
    memcpy(c->disp_info.vendor, buf, vendor_length);
    c->disp_info.vendor[vendor_length] = ''\0'`;
    buf += XP_PAD(vendor_length);

ALLOC(XP_FORMAT, c->disp_info.pixmap_formats, c->disp_info.pixmap_formats_length)
    for(i = 0; i < c->disp_info.pixmap_formats_length; ++i)
    {INDENT()
UNPACK(XP_FORMAT, `c->disp_info.pixmap_formats[i]')
        buf += SIZEOF(XP_FORMAT);
    }UNINDENT()

ALLOC(XP_SCREEN, c->disp_info.roots, c->disp_info.roots_length)
    for(i = 0; i < c->disp_info.roots_length; ++i)
    {INDENT()
UNPACK(XP_SCREEN, `c->disp_info.roots[i]')
        buf += SIZEOF(XP_SCREEN);

ALLOC(XP_DEPTH, c->disp_info.roots[i].allowed_depths, c->disp_info.roots[i].allowed_depths_length)
        for(j = 0; j < c->disp_info.roots[i].allowed_depths_length; ++j)
        {INDENT()
UNPACK(XP_DEPTH, `c->disp_info.roots[i].allowed_depths[j]')
            buf += SIZEOF(XP_DEPTH);

ALLOC(XP_VISUALTYPE, c->disp_info.roots[i].allowed_depths[j].visuals, c->disp_info.roots[i].allowed_depths[j].visuals_length)
            for(k = 0; k < c->disp_info.roots[i].allowed_depths[j].visuals_length; ++k)
            {INDENT()
UNPACK(XP_VISUALTYPE, `c->disp_info.roots[i].allowed_depths[j].visuals[k]')
                buf += SIZEOF(XP_VISUALTYPE);
            }UNINDENT()
        }UNINDENT()
    }UNINDENT()

    buf = tmp;

    /* clean up */
    free(buf);
    return c;
')
define(`_outdiv',-1)dnl

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

REQUEST(void, ChangeProperty, 18, mode, `
PARAM(XP_WINDOW, `window')
PARAM(XP_ATOM, `property')
PARAM(XP_ATOM, `type')
PARAM(XP_CARD8, `format')
PAD(3)
PARAM(XP_CARD32, `data_length')
LISTPARAM(XP_BYTE, `data', `data_length * format / 8')
')
