
#ifndef __XCB_IMAGE_H__
#define __XCB_IMAGE_H__


typedef struct XCBImage_ XCBImage;

struct XCBImage_
{
  CARD16         width;
  CARD16         height;
  unsigned int   xoffset;
  CARD8          format;
  BYTE          *data;
  CARD8          image_byte_order;
  CARD8          bitmap_format_scanline_unit;
  CARD8          bitmap_format_bit_order;
  CARD8          bitmap_format_scanline_pad;
  CARD8          depth;
  CARD32         bytes_per_line;
  CARD8          bits_per_pixel;
};

typedef struct XCBShmSegmentInfo_ XCBShmSegmentInfo;

struct XCBShmSegmentInfo_
{
  XCBShmSEG shmseg;
  CARD32    shmid;
  BYTE     *shmaddr;
};

XCBImage *xcb_image_create (XCBConnection *conn,
			    CARD8          depth,
			    CARD8          format,
			    unsigned int   offset,
			    BYTE          *data,
			    CARD16         width,
			    CARD16         height,
			    CARD8          xpad,
			    CARD32         bytes_per_line);

int xcb_image_init (XCBImage *image);

int xcb_image_destroy (XCBImage *image);

XCBImage *xcb_image_get (XCBConnection *conn,
			 XCBDRAWABLE    draw,
			 INT16          x,
			 INT16          y,
			 CARD16         width,
			 CARD16         height,
			 CARD32         plane_mask,
			 CARD8          format);

/* Not implemented. Should be ? */
XCBImage xcb_image_subimage_get (XCBConnection *conn,
				 XCBDRAWABLE    draw,
				 int            x,
				 int            y,
				 unsigned int   width,
				 unsigned int   height,
				 unsigned long  plane_mask,
				 CARD8          format,
				 XCBImage      *dest_im,
				 int            dest_x,
				 int            dest_y);

int xcb_image_put (XCBConnection *conn,
		   XCBDRAWABLE    draw,
		   XCBGCONTEXT    gc,
		   XCBImage      *image,
		   INT16          x_offset,
		   INT16          y_offset,
		   INT16          x,
		   INT16          y,
		   CARD16         width,
		   CARD16         height);

int xcb_image_put_pixel (XCBImage *image,
			 int       x,
			 int       y,
			 CARD32    pixel);

CARD32 xcb_image_get_pixel (XCBImage *image,
			    int       x,
			    int       y);

/*
 * Shm stuff
 */

XCBImage *xcb_shm_image_create (XCBConnection *conn,
				CARD8          depth,
				CARD8          format,
				BYTE          *data,
				CARD16         width,
				CARD16         height);

int xcb_shm_image_destroy (XCBImage *image);

int xcb_shm_image_put (XCBConnection *conn,
		       XCBDRAWABLE    draw,
		       XCBGCONTEXT    gc,
		       XCBImage      *image,
		       XCBShmSegmentInfo shminfo,
		       INT16          src_x,
		       INT16          src_y,
		       INT16          dest_x,
		       INT16          dest_y,
		       CARD16         src_width,
		       CARD16         src_height,
		       CARD8          send_event);

int xcb_shm_image_get (XCBConnection *conn,
		       XCBDRAWABLE    draw,
		       XCBImage      *image,
		       XCBShmSegmentInfo shminfo,
		       INT16          x,
		       INT16          y,
		       CARD32         plane_mask);


#endif /* __XCB_IMAGE_H__ */
