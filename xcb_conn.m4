_C`'#include <assert.h>
_C`'#include <sys/types.h>
_C`'#include <sys/socket.h>
_C`'#include <sys/un.h>
_C`'#include <netinet/in.h>
_C`'#include <netdb.h>
_C`'#include <stdio.h>
_C`'#include <unistd.h>
_C`'#include <stdlib.h>
_H`'#include <pthread.h>
_C
_C`'#include "xcb_conn.h"

_H`'#define XP_PAD(E) ((4-((E)%4))%4)
_H
_H`'include(`xcb_types.m4')
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
_H`'struct XCB_Connection; /* forward declare */
_H`'struct XCB_Reply_Data; /* forward declare */
_H`'typedef int (*XCB_Reply_Handler)(struct XCB_Connection *,
_H`'    struct XCB_Reply_Data *, unsigned char *);
_H
STRUCT(XCB_Reply_Data, `
FIELD(pthread_mutex_t, `pending')
FIELD(int, `received')
FIELD(XCB_Reply_Handler, `reply_handler')
FIELD(int, `seqnum')
POINTERFIELD(void, `data')
POINTERFIELD(struct XCB_Reply_Data, `next')
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
POINTERFIELD(XCB_Reply_Data, `reply_data_head')
POINTERFIELD(XCB_Reply_Data, `reply_data_tail')
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
FUNCTION(`', `int XCB_Add_Reply_Data', dnl
`XCB_Connection *c, XCB_Reply_Data *cur', `
    assert(cur);
    cur->next = 0;
    if(c->reply_data_tail)
        c->reply_data_tail->next = cur;
    else
        c->reply_data_head = cur;

    c->reply_data_tail = cur;
    return 1;
')

/* PRE: c is locked and cur points to valid memory */
/* POST: *cur points at the desired data or is 0; if prev was not 0,
         (*prev)->next points at the desired data or *prev is 0 */
FUNCTION(`', `int XCB_Find_Reply_Data', dnl
`XCB_Connection *c, int seqnum, XCB_Reply_Data **cur, XCB_Reply_Data **prev', `
    assert(cur);
    if(prev)
        *prev = 0;
    *cur = c->reply_data_head;
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
FUNCTION(`', `int XCB_Remove_Reply_Data', dnl
`XCB_Connection *c, XCB_Reply_Data *cur, XCB_Reply_Data *prev', `
    assert(cur);
    assert(prev ? prev->next == cur : c->reply_data_head == cur);

    if(prev)
        prev->next = cur->next;
    else
        c->reply_data_head = cur->next;

    if(!cur->next)
        c->reply_data_tail = prev;

    return 1;
')

FUNCTION(`', `int XCB_Wait_Once', `XCB_Connection *c', `
    unsigned char *buf;
    int seqnum;
    XP_CARD32 length;
    XCB_Reply_Data *cur;

ALLOC(unsigned char, buf, 32)

    XCB_Read(c, buf, 32);
    switch(buf[0])
    {INDENT()
    case 0: /* error */
        break;
    case 1: /* reply */
define(`_index', 2)dnl
UNPACK(XP_CARD16, `seqnum')
        XCB_Find_Reply_Data(c, seqnum, &cur, 0);
        if(!cur)
        {
            printf("Got reply for seqnum %d but no data found!\n", seqnum);
            abort();
        }
define(`_index', 4)dnl
UNPACK(XP_CARD32, `length')
        if(length)
        {INDENT()
REALLOC(unsigned char, buf, 32 + length * 4)
            XCB_Read(c, buf + 32, length * 4);
        }UNINDENT()
        cur->reply_handler(c, cur, buf);
        break;
    default: /* event */
    }UNINDENT()
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
pushdef(`_outdiv',0)dnl
FUNCTION(`', `XCB_Connection *XCB_Connect', `int fd', `
dnl using calloc to make gdb use slightly less painful
    XCB_Connection* c = (XCB_Connection*) calloc(1, sizeof(XCB_Connection));
    int i, j, k, vendor_length, additional_data_length;
    unsigned char *tmp, *buf;
    assert(c);

    c->fd = fd;
    pthread_mutex_init(&c->locked, 0);
    c->n_outqueue = 0;
    c->reply_data_head = 0;
    c->reply_data_tail = 0;

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
    buf += vendor_length + XP_PAD(vendor_length);

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
popdef(`_outdiv')dnl
