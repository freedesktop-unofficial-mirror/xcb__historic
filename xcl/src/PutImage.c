/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"
#include <X11/Xutil.h>
#include <stdio.h>

int XPutImage(Display *dpy, Drawable d, GC gc, XImage *image,
    int req_xoffset, int req_yoffset, int x, int y,
    unsigned int req_width, unsigned int req_height)
{
    unsigned int alignment, image_size, bytes_per_line, unaligned_bits;
    unsigned int unaligned_bytes, bytes_per_image_line;
    unsigned int image_alignment;
    char  *image_data, *line_ptr, *image_line_ptr;
    int index;
    
    /* find out how large the image is going to be */
    alignment = image->bitmap_unit >> 3;
    image_alignment = image->bitmap_pad >> 3;
    unaligned_bits = image->bits_per_pixel * req_width;
    /* give it the extra pad byte if it is needed */
    unaligned_bytes = (unaligned_bits + 7) >> 3;
    bytes_per_line = ( (unaligned_bytes + (alignment - 1) ) / alignment ) * alignment;
    image_size = bytes_per_line * req_height;

    bytes_per_image_line = ( (unaligned_bytes + (image_alignment - 1) ) / image_alignment ) * image_alignment;

    /* bytes_per_image_line is the number of bytes per scanline in the 
     * source image */

    line_ptr = image_data = malloc( image_size );
    image_line_ptr = image->data;
    for(index = 0; index < req_height; index++)
    {
        memcpy(line_ptr, image_line_ptr, bytes_per_image_line);
        line_ptr += bytes_per_line;
        image_line_ptr += (image->bytes_per_line);
    }

    XCBPutImage(XCBConnectionOfDisplay(dpy), image->format, XCLDRAWABLE(d), XCLGCONTEXT(gc->gid), req_width, req_height, req_xoffset, req_yoffset, 0, image->depth, image_size, image_data);
    free( image_data );
    return 0;
}
