/* gcc -g -O2 -Wall -c `pkg-config --cflags xcb` -o xcb_image.o xcb_image.c */

#include <stdlib.h>
#include <stdio.h>

#include <X11/XCB/xcb.h>
#include <X11/XCB/xcbint.h>
#include <X11/XCB/shm.h>
#include <X11/Xlib.h>

#include "xcb_image.h"

static int xcb_put_pixel_generic (XCBImage *image, int x, int y, CARD32 pixel);
static int xcb_put_pixel32       (XCBImage *image, int x, int y, CARD32 pixel);
static int xcb_put_pixel16       (XCBImage *image, int x, int y, CARD32 pixel);
static int xcb_put_pixel8        (XCBImage *image, int x, int y, CARD32 pixel);
static int xcb_put_pixel1        (XCBImage *image, int x, int y, CARD32 pixel);

static CARD32 xcb_get_pixel_generic (XCBImage *image, int x, int y);
static CARD32 xcb_get_pixel32       (XCBImage *image, int x, int y);
static CARD32 xcb_get_pixel16       (XCBImage *image, int x, int y);
static CARD32 xcb_get_pixel8        (XCBImage *image, int x, int y);
static CARD32 xcb_get_pixel1        (XCBImage *image, int x, int y);

/* Convenient */
static CARD8          xcb_bits_per_pixel   (XCBConnection *c, CARD8 depth);
static CARD32         xcb_bytes_per_line   (CARD8 pad, CARD16 width, CARD8 bpp);
static CARD8          xcb_scanline_pad_get (XCBConnection *conn,
					    CARD8          depth);

static CARD8 const _lomask[0x09] = { 0x00, 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff };
static CARD8 const _himask[0x09] = { 0xff, 0xfe, 0xfc, 0xf8, 0xf0, 0xe0, 0xc0, 0x80, 0x00 };

static unsigned char const _reverse_byte[0x100] = {
	0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0,
	0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0,
	0x08, 0x88, 0x48, 0xc8, 0x28, 0xa8, 0x68, 0xe8,
	0x18, 0x98, 0x58, 0xd8, 0x38, 0xb8, 0x78, 0xf8,
	0x04, 0x84, 0x44, 0xc4, 0x24, 0xa4, 0x64, 0xe4,
	0x14, 0x94, 0x54, 0xd4, 0x34, 0xb4, 0x74, 0xf4,
	0x0c, 0x8c, 0x4c, 0xcc, 0x2c, 0xac, 0x6c, 0xec,
	0x1c, 0x9c, 0x5c, 0xdc, 0x3c, 0xbc, 0x7c, 0xfc,
	0x02, 0x82, 0x42, 0xc2, 0x22, 0xa2, 0x62, 0xe2,
	0x12, 0x92, 0x52, 0xd2, 0x32, 0xb2, 0x72, 0xf2,
	0x0a, 0x8a, 0x4a, 0xca, 0x2a, 0xaa, 0x6a, 0xea,
	0x1a, 0x9a, 0x5a, 0xda, 0x3a, 0xba, 0x7a, 0xfa,
	0x06, 0x86, 0x46, 0xc6, 0x26, 0xa6, 0x66, 0xe6,
	0x16, 0x96, 0x56, 0xd6, 0x36, 0xb6, 0x76, 0xf6,
	0x0e, 0x8e, 0x4e, 0xce, 0x2e, 0xae, 0x6e, 0xee,
	0x1e, 0x9e, 0x5e, 0xde, 0x3e, 0xbe, 0x7e, 0xfe,
	0x01, 0x81, 0x41, 0xc1, 0x21, 0xa1, 0x61, 0xe1,
	0x11, 0x91, 0x51, 0xd1, 0x31, 0xb1, 0x71, 0xf1,
	0x09, 0x89, 0x49, 0xc9, 0x29, 0xa9, 0x69, 0xe9,
	0x19, 0x99, 0x59, 0xd9, 0x39, 0xb9, 0x79, 0xf9,
	0x05, 0x85, 0x45, 0xc5, 0x25, 0xa5, 0x65, 0xe5,
	0x15, 0x95, 0x55, 0xd5, 0x35, 0xb5, 0x75, 0xf5,
	0x0d, 0x8d, 0x4d, 0xcd, 0x2d, 0xad, 0x6d, 0xed,
	0x1d, 0x9d, 0x5d, 0xdd, 0x3d, 0xbd, 0x7d, 0xfd,
	0x03, 0x83, 0x43, 0xc3, 0x23, 0xa3, 0x63, 0xe3,
	0x13, 0x93, 0x53, 0xd3, 0x33, 0xb3, 0x73, 0xf3,
	0x0b, 0x8b, 0x4b, 0xcb, 0x2b, 0xab, 0x6b, 0xeb,
	0x1b, 0x9b, 0x5b, 0xdb, 0x3b, 0xbb, 0x7b, 0xfb,
	0x07, 0x87, 0x47, 0xc7, 0x27, 0xa7, 0x67, 0xe7,
	0x17, 0x97, 0x57, 0xd7, 0x37, 0xb7, 0x77, 0xf7,
	0x0f, 0x8f, 0x4f, 0xcf, 0x2f, 0xaf, 0x6f, 0xef,
	0x1f, 0x9f, 0x5f, 0xdf, 0x3f, 0xbf, 0x7f, 0xff
};

int
_XReverse_Bytes(register CARD8 *bpt,
		register int    nb)
{
  do {
    *bpt = _reverse_byte[*bpt];
    bpt++;
  } while (--nb > 0);
  return 0;
}

static void
_xynormalizeimagebits (register CARD8    *bp,
		       register XCBImage *img)
{
  register CARD8 c;
  
  if (img->image_byte_order != img->bitmap_format_bit_order)
    {
      switch (img->bitmap_format_scanline_unit)
	{
	  
	case 16:
	  c = *bp;
	  *bp = *(bp + 1);
	  *(bp + 1) = c;
	  break;
	  
	case 32:
	  c = *(bp + 3);
	  *(bp + 3) = *bp;
	  *bp = c;
	  c = *(bp + 2);
	  *(bp + 2) = *(bp + 1);
	  *(bp + 1) = c;
	  break;
	}
    }
  if (img->bitmap_format_bit_order == MSBFirst)
    _XReverse_Bytes (bp, img->bitmap_format_scanline_unit >> 3);
}

static void
_znormalizeimagebits (register CARD8    *bp,
		      register XCBImage *img)
{
  register CARD8 c;
  
  switch (img->bits_per_pixel)
    {
    case 4:
      *bp = ((*bp >> 4) & 0xF) | ((*bp << 4) & ~0xF);
      break;
      
    case 16:
      c = *bp;
      *bp = *(bp + 1);
      *(bp + 1) = c;
      break;
      
    case 24:
      c = *(bp + 2);
      *(bp + 2) = *bp;
      *bp = c;
      break;
      
    case 32:
      c = *(bp + 3);
      *(bp + 3) = *bp;
      *bp = c;
      c = *(bp + 2);
      *(bp + 2) = *(bp + 1);
      *(bp + 1) = c;
      break;
    }
}

static void
_putbits(register BYTE *src,   /* address of source bit string */
	 int dstoffset,        /* bit offset into destination; range is 0-31 */
	 register int numbits, /* number of bits to copy to destination */
	 register BYTE *dst)   /* address of destination bit string */
{
  register CARD8 chlo, chhi;
  int hibits;
  
  dst = dst + (dstoffset >> 3);
  dstoffset = dstoffset & 7;
  hibits = 8 - dstoffset;
  chlo = *dst & _lomask[dstoffset];

  for (;;) {
    chhi = (*src << dstoffset) & _himask[dstoffset];
    if (numbits <= hibits) {
      chhi = chhi & _lomask[dstoffset + numbits];
      *dst = (*dst & _himask[dstoffset + numbits]) | chlo | chhi;
      break;
    }
    *dst = chhi | chlo;
    dst++;
    numbits = numbits - hibits;
    chlo = (CARD8) (*src & _himask[hibits]) >> hibits;
    src++;
    if (numbits <= dstoffset) {
      chlo = chlo & _lomask[numbits];
      *dst = (*dst & _himask[numbits]) | chlo;
      break;
    }
    numbits = numbits - dstoffset;
  }	
}

static unsigned int Ones(                /* HACKMEM 169 */
    CARD32 mask)
{
    register CARD32 y;

    y = (mask >> 1) &033333333333;
    y = mask - y - ((y >>1) & 033333333333);
    return ((unsigned int) (((y + (y >> 3)) & 030707070707) % 077));
}

/*
 * Macros
 *
 * The XYNORMALIZE macro determines whether XY format data requires 
 * normalization and calls a routine to do so if needed. The logic in
 * this module is designed for LSBFirst byte and bit order, so 
 * normalization is done as required to present the data in this order.
 *
 * The ZNORMALIZE macro performs byte and nibble order normalization if 
 * required for Z format data.
 *
 * The XYINDEX macro computes the index to the starting byte (char) boundary
 * for a bitmap_unit containing a pixel with coordinates x and y for image
 * data in XY format.
 * 
 * The ZINDEX macro computes the index to the starting byte (char) boundary 
 * for a pixel with coordinates x and y for image data in ZPixmap format.
 * 
 */

#define XYNORMALIZE(bp, img) \
    if ((img->image_byte_order == MSBFirst) || (img->bitmap_format_bit_order == MSBFirst)) \
	_xynormalizeimagebits((unsigned char *)(bp), img)

#define ZNORMALIZE(bp, img) \
    if (img->image_byte_order == MSBFirst) \
	_znormalizeimagebits((unsigned char *)(bp), img)

#define XYINDEX(x, y, img) \
    ((y) * img->bytes_per_line) + \
    (((x) + img->xoffset) / img->bitmap_format_scanline_unit) * (img->bitmap_format_scanline_unit >> 3)

#define ZINDEX(x, y, img) ((y) * img->bytes_per_line) + \
    (((x) * img->bits_per_pixel) >> 3)


/* Convenient functions */

static CARD8
xcb_bits_per_pixel (XCBConnection *c, CARD8 depth)
{ 
  XCBFORMAT *fmt = XCBConnSetupSuccessRepPixmapFormats(XCBGetSetup(c));
  XCBFORMAT *fmtend = fmt + XCBConnSetupSuccessRepPixmapFormatsLength(XCBGetSetup(c));
  
  for(; fmt != fmtend; ++fmt)
    if(fmt->depth == depth)
      return fmt->bits_per_pixel;
  
  if(depth <= 4)
    return 4;
  if(depth <= 8)
    return 8;
  if(depth <= 16)
    return 16;
  return 32;
}

static CARD32
xcb_bytes_per_line (CARD8 pad, CARD16 width, CARD8 bpp)
{
  return ((bpp * width + pad - 1) & -pad) >> 3;
}

static CARD8
xcb_scanline_pad_get (XCBConnection *conn,
		      CARD8          depth)
{
  XCBFORMAT *fmt = XCBConnSetupSuccessRepPixmapFormats(XCBGetSetup(conn));
  XCBFORMAT *fmtend = fmt + XCBConnSetupSuccessRepPixmapFormatsLength(XCBGetSetup(conn));
  
  for(; fmt != fmtend; ++fmt)
    if(fmt->depth == depth)
      {
	printf ("dans test %d\n", fmt->scanline_pad);
	return fmt->scanline_pad;
      }
  printf ("pas dans test %d\n", XCBGetSetup (conn)->bitmap_format_scanline_pad);
  return XCBGetSetup (conn)->bitmap_format_scanline_pad;

/*   XCBFORMATIter iter; */
/*   int           cur; */

/*   iter =  XCBConnSetupSuccessRepPixmapFormatsIter (conn->setup); */
/*   for (cur = 0 ; cur < iter.rem ; cur++, XCBFORMATNext (&iter)) */
/*     if (iter.data->depth == depth) */
/*       return iter.data->scanline_pad; */
  
/*   return XCBGetSetup (conn)->bitmap_format_scanline_pad; */
}


XCBImage *
xcb_image_create (XCBConnection *conn,
		  CARD8          depth,
		  CARD8          format,
		  unsigned int   offset,
		  BYTE          *data,
		  CARD16         width,
		  CARD16         height,
		  CARD8          xpad,
		  CARD32         bytes_per_line)
{
  XCBImage      *image;
  XCBConnSetupSuccessRep *rep;
  CARD8                   bpp = 1; /* bits per pixel */

  if (depth == 0 || depth > 32 ||
      (format != XYBitmap && format != XYPixmap && format != ZPixmap) ||
      (format == XYBitmap && depth != 1) ||
      (xpad != 8 && xpad != 16 && xpad != 32))
    return (XCBImage *) NULL;

  image = (XCBImage *)malloc (sizeof (XCBImage));
  if (image == NULL)
    return NULL;
  
  rep = XCBGetSetup (conn);

  image->width = width;
  image->height = height;
  image->format = format;
  image->image_byte_order = rep->image_byte_order;
  image->bitmap_format_scanline_unit = rep->bitmap_format_scanline_unit;
  image->bitmap_format_bit_order = rep->bitmap_format_bit_order;
  image->bitmap_format_scanline_pad = xpad;
  
  if (format == ZPixmap) 
    {
      bpp = xcb_bits_per_pixel (conn, depth);
    }

  image->xoffset = offset;
  image->depth = depth;
  image->data = data;

  /*
   * compute per line accelerator.
   */
  if (bytes_per_line == 0)
    {
      if (format == ZPixmap)
	image->bytes_per_line = 
	  xcb_bytes_per_line (image->bitmap_format_scanline_pad,
			      width, bpp);
      else
	image->bytes_per_line =
	  xcb_bytes_per_line (image->bitmap_format_scanline_pad,
			      width + offset, 1);
    }
  else
    image->bytes_per_line = bytes_per_line;

  image->bits_per_pixel = bpp;

  return image;
}

int
xcb_image_init (XCBImage *image)
{
  if ((image->depth == 0 || image->depth > 32) ||
      (image->format != XYBitmap &&
       image->format != XYPixmap &&
       image->format != ZPixmap) ||
      (image->format == XYBitmap && image->depth != 1) ||
      (image->bitmap_format_scanline_pad != 8 &&
       image->bitmap_format_scanline_pad != 16 &&
       image->bitmap_format_scanline_pad != 32))
    return 0;
  
  /*
   * compute per line accelerator.
   */
  if (image->bytes_per_line == 0)
    {
      if (image->format == ZPixmap)
	image->bytes_per_line = 
	  xcb_bytes_per_line (image->bitmap_format_scanline_pad,
			      image->width,
			      image->bits_per_pixel);
      else
	image->bytes_per_line = 
	  xcb_bytes_per_line (image->bitmap_format_scanline_pad,
			      image->width + image->xoffset,
			      1);
    }
  
  return 1;
}

int
xcb_image_destroy (XCBImage *image)
{
  if (image->data != NULL)
    free (image->data);
  free (image);

  return 1;
}

XCBImage *
xcb_image_get (XCBConnection *conn,
	       XCBDRAWABLE    draw,
	       INT16          x,
	       INT16          y,
	       CARD16         width,
	       CARD16         height,
	       CARD32         plane_mask,
	       CARD8          format)
{
  XCBImage       *image;
  XCBGetImageRep *rep;
  BYTE           *data;

  rep = XCBGetImageReply (conn, 
			  XCBGetImage (conn,
				       format,
				       draw,
				       x, y,
				       width, height,
				       plane_mask),
			  NULL);
  if (!rep)
    return NULL;

  printf ("Format %d\n", format);
  printf ("Length %d\n", XCBGetImageDataLength(rep));
  printf ("Length %ld\n", rep->length);
  printf ("depth %d\n", rep->depth);

  data = XCBGetImageData (rep);

  if (format == XYPixmap)
    {
      image = xcb_image_create (conn,
				Ones (plane_mask &
				      (((unsigned long)0xFFFFFFFF) >> (32 - rep->depth))),
				format,
				0,
				data,
				width, height,
				xcb_scanline_pad_get (conn, rep->depth),
				0);
    }
  else /* format == ZPixmap */
    {
      printf ("Format : ZPixmap %d\n", xcb_scanline_pad_get (conn, rep->depth));
      image = xcb_image_create (conn,
				rep->depth,
				ZPixmap,
				0,
				data,
				width, height,
				xcb_scanline_pad_get (conn, rep->depth),
				0);
    }
  if (!image)
    free (data);

  return image;
}

int
xcb_image_put (XCBConnection *conn,
	       XCBDRAWABLE    draw,
	       XCBGCONTEXT    gc,
	       XCBImage      *image,
	       INT16          x_offset,
	       INT16          y_offset,
	       INT16          x,
	       INT16          y,
	       CARD16         width,
	       CARD16         height)
{
  INT32 w;
  INT32 h;
  int dest_bits_per_pixel;
  int dest_scanline_pad;
  int left_pad;

  w = width;
  h = height;

  if (x_offset < 0)
    {
      w += x_offset;
      x_offset = 0;
    }

  if (y_offset < 0)
    {
      h += y_offset;
      y_offset = 0;
    }

  if ((w + x_offset) > image->width)
    w = image->width - x_offset;

  if ((h + y_offset) > image->height)
    h = image->height - y_offset;

  if ((w <= 0) || (h <= 0))
    return 0;

  if ((image->bits_per_pixel == 1) || (image->format != ZPixmap))
    {
      dest_bits_per_pixel = 1;
      dest_scanline_pad = XCBGetSetup (conn)->bitmap_format_scanline_pad;
      left_pad = image->xoffset & (XCBGetSetup (conn)->bitmap_format_scanline_unit- 1);
      printf ("PutImage Format xypixmap %d\n", image->format);
    }
  else
    {
      XCBFORMATIter iter;
      int           cur;
      
      printf ("PutImage Format zpixmap %d\n", image->format);

      dest_bits_per_pixel = image->bits_per_pixel;
      dest_scanline_pad = image->bitmap_format_scanline_pad;
      left_pad = 0;
      iter =  XCBConnSetupSuccessRepPixmapFormatsIter (conn->setup);
      for (cur = 0 ; cur < iter.rem ; cur++, XCBFORMATNext (&iter))
	if (iter.data->depth == image->depth)
	  {
	    dest_bits_per_pixel = iter.data->bits_per_pixel;
	    dest_scanline_pad = iter.data->scanline_pad;
	  }
      
      if (dest_bits_per_pixel != image->bits_per_pixel) {
	XCBImage       img;
	register INT32 i, j;
	XCBConnSetupSuccessRep *rep;
	
	printf ("Truc slow\n");

	/* XXX slow, but works */
	rep = XCBGetSetup (conn);
	img.width = width;
	img.height = height;
	img.xoffset = 0;
	img.format = ZPixmap;
	img.image_byte_order = rep->image_byte_order;
	img.bitmap_format_scanline_unit = rep->bitmap_format_scanline_unit;
	img.bitmap_format_bit_order = rep->bitmap_format_bit_order;
	img.bitmap_format_scanline_pad = dest_scanline_pad;
	img.depth = image->depth;
	img.bits_per_pixel = dest_bits_per_pixel;
	img.bytes_per_line =  xcb_bytes_per_line (dest_scanline_pad,
						  width,
						  dest_bits_per_pixel);
	img.data = malloc((CARD8) (img.bytes_per_line * height));
	
	if (img.data == NULL)
	  return 0;
	
	for (j = height; --j >= 0; )
	  for (i = width; --i >= 0; )
	    xcb_image_put_pixel(&img,
				i, j,
				xcb_image_get_pixel(image,
						    x_offset + i,
						    y_offset + j));
	
	XCBPutImage(conn, img.format, draw, gc,
		    w, h, x, y,
		    dest_scanline_pad,
		    img.depth,
		    img.bytes_per_line * height,
		    img.data);
	
	free(img.data);
	return 0;
      }
    }
  printf ("Pas slow %ld %d %d %d\n", image->bytes_per_line, height,
	dest_scanline_pad, left_pad);
  int i, j;
  CARD32    pixel1;
  for (j = 0 ; j < image->height ; j++)
    {
      for (i = 0 ; i < image->width ; i++)
	{
	  pixel1 = xcb_image_get_pixel (image, i, j);
	  printf ("%6ld ", pixel1);
	}
      printf ("\n");
    }

  XCBPutImage(conn, image->format, draw, gc,
	      w, h, x, y,
	      left_pad,
	      image->depth, image->bytes_per_line * height,
	      image->data);

  return 0;
}

int
xcb_image_put_pixel (XCBImage *image,
		     int       x,
		     int       y,
		     CARD32    pixel)
{
  if ((image->format == ZPixmap) && (image->bits_per_pixel == 8)) 
    return xcb_put_pixel8 (image, x, y, pixel);
  else if (((image->bits_per_pixel | image->depth) == 1) &&
	     (image->image_byte_order == image->bitmap_format_bit_order))
    return xcb_put_pixel1 (image, x, y, pixel);
  else if ((image->format == ZPixmap) &&
	     (image->bits_per_pixel == 32))
    return xcb_put_pixel32 (image, x, y, pixel);
  else if ((image->format == ZPixmap) &&
	     (image->bits_per_pixel == 16))
    return xcb_put_pixel16 (image, x, y, pixel);
  else
    return xcb_put_pixel_generic (image, x, y, pixel);
}

CARD32
xcb_image_get_pixel (XCBImage *image,
		     int       x,
		     int       y)
{
  if ((image->format == ZPixmap) && (image->bits_per_pixel == 8)) 
    return xcb_get_pixel8 (image, x, y);
  else if (((image->bits_per_pixel | image->depth) == 1) &&
	     (image->image_byte_order == image->bitmap_format_bit_order))
    return xcb_get_pixel1 (image, x, y);
  else if ((image->format == ZPixmap) &&
	     (image->bits_per_pixel == 32))
    return xcb_get_pixel32 (image, x, y);
  else if ((image->format == ZPixmap) &&
	     (image->bits_per_pixel == 16))
    return xcb_get_pixel16 (image, x, y);
  else
    return xcb_get_pixel_generic (image, x, y);
}

/*
 * Shm stuff
 */

XCBImage *
xcb_shm_image_create (XCBConnection *conn,
		      CARD8          depth,
		      CARD8          format,
		      BYTE          *data,
		      CARD16         width,
		      CARD16         height)
{
  XCBImage               *image;
  XCBConnSetupSuccessRep *rep;

  image = (XCBImage *)malloc (sizeof (XCBImage));
  if (!image)
    return NULL;
  
  rep = XCBGetSetup (conn);
  
  image->width = width;
  image->height = height;
  image->xoffset = 0;
  image->format = format;
  image->data = data;
  image->depth = depth;

  image->image_byte_order = rep->image_byte_order;
  image->bitmap_format_scanline_unit = rep->bitmap_format_scanline_unit;
  image->bitmap_format_bit_order = rep->bitmap_format_bit_order;
  image->bitmap_format_scanline_pad = xcb_scanline_pad_get (conn, depth);

  if (format == ZPixmap)
    image->bits_per_pixel = xcb_bits_per_pixel (conn, depth);
  else
    image->bits_per_pixel = 1;

  image->bytes_per_line = xcb_bytes_per_line (image->bitmap_format_scanline_pad,
					      width,
					      image->bits_per_pixel);

  return image;
}

int
xcb_shm_image_destroy (XCBImage *image)
{
  if (image)
    free (image);
  
  return 1;
}

int
xcb_shm_image_put (XCBConnection *conn,
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
		   CARD8          send_event)
{
  if (!shminfo.shmaddr)
    return 0;

  XCBShmPutImage(conn, draw, gc,
		 image->width, image->height,
		 src_x, src_y, src_width, src_height,
		 dest_x, dest_y,
		 image->depth, image->format,
		 send_event, 
		 shminfo.shmseg,
		 image->data - shminfo.shmaddr);
  return 1;
}

int
xcb_shm_image_get (XCBConnection *conn,
		   XCBDRAWABLE    draw,
		   XCBImage      *image,
		   XCBShmSegmentInfo shminfo,
		   INT16          x,
		   INT16          y,
		   CARD32         plane_mask)
{
  XCBShmGetImageRep *rep;
  XCBShmGetImageCookie cookie;

  if (!shminfo.shmaddr)
    return 0;

  cookie = XCBShmGetImage(conn, draw,
			  x, y,
			  image->width, image->height,
			  plane_mask,
			  image->format,
			  shminfo.shmseg,
			  image->data - shminfo.shmaddr);
  rep = XCBShmGetImageReply(conn, cookie, NULL);
  /* rep would be useful to get the visual id */
  /* but i don't use it */
  /* So, should we remove it ? */
  
  return 1;
}

/*
 * Private
 */

/* PutPixel */

#ifndef WORD64
static CARD32 const byteorderpixel = MSBFirst << 24;
#endif

static int
xcb_put_pixel_generic (XCBImage *image, int x, int y, CARD32 pixel)
{
  CARD32         px, npixel;
  register BYTE *src;
  register BYTE *dst;
  register int i;
  int j, nbytes;
  long plane;

  printf ("put pixel generic\n");

  if (image->depth == 4)
    pixel &= 0xf;
  npixel = pixel;

  for (i =0 , px = pixel; i < sizeof(CARD32); i++, px >>= 8)
    ((CARD8 *)&pixel)[i] = px;

  if ((image->bits_per_pixel | image->depth) == 1)
    {
      src = &image->data[XYINDEX(x, y, image)];
      dst = (BYTE *)&px;
      px = 0;
      nbytes = image->bitmap_format_scanline_unit >> 3;
      for (i = nbytes; --i >= 0; ) *dst++ = *src++;
      XYNORMALIZE(&px, image);
      i = ((x + image->xoffset) % image->bitmap_format_scanline_unit);
      _putbits ((BYTE *)&pixel, i, 1, (BYTE *)&px);
      XYNORMALIZE(&px, image);
      src = (BYTE *) &px;
      dst = &image->data[XYINDEX(x, y, image)];
      for (i = nbytes; --i >= 0; ) *dst++ = *src++;
    }
  else
    if (image->format == XYPixmap)
      {
	plane = ((image->bytes_per_line * image->height) *
		 (image->depth - 1)); /* do least signif plane 1st */
	nbytes = image->bitmap_format_scanline_unit >> 3;
	for (j = image->depth; --j >= 0; )
	  {
	    src = &image->data[XYINDEX(x, y, image) + plane];
	    dst = (BYTE *) &px;
	    px = 0;
	    for (i = nbytes; --i >= 0; ) *dst++ = *src++;
	    XYNORMALIZE(&px, image);
	    i = ((x + image->xoffset) % image->bitmap_format_scanline_unit);
	    _putbits ((BYTE *)&pixel, i, 1, (BYTE *)&px);
	    XYNORMALIZE(&px, image);
	    src = (BYTE *)&px;
	    dst = &image->data[XYINDEX(x, y, image) + plane];
	    for (i = nbytes; --i >= 0; ) *dst++ = *src++;
	    npixel = npixel >> 1;
	    for (i = 0, px = npixel; i<sizeof(CARD32); i++, px >>= 8)
	      ((CARD8 *)&pixel)[i] = px;
	    plane = plane - (image->bytes_per_line * image->height);
	  }
      }
    else
      if (image->format == ZPixmap)
	{
	  src = &image->data[ZINDEX(x, y, image)];
	  dst = (BYTE *)&px;
	  px = 0;
	  nbytes = (image->bits_per_pixel + 7) >> 3;
	  for (i = nbytes; --i >= 0; ) *dst++ = *src++;
	  ZNORMALIZE(&px, image);
	  _putbits ((BYTE *)&pixel, 
		    (x * image->bits_per_pixel) & 7, 
		    image->bits_per_pixel, (BYTE *)&px);
	  ZNORMALIZE(&px, image);
	  src = (BYTE *)&px;
	  dst = &image->data[ZINDEX(x, y, image)];
	  for (i = nbytes; --i >= 0; ) *dst++ = *src++;
	}
      else
	{
	  return 0; /* bad image */
	}
  return 1;
}

static int
xcb_put_pixel32 (XCBImage *image, int x, int y, CARD32 pixel)
{
  CARD8 *addr;

  if ((image->format == ZPixmap) &&
      (image->bits_per_pixel ==32))
    {
      addr = &((CARD8 *)image->data)
	[y * image->bytes_per_line + (x << 2)];
#ifndef WORD64
      if (*((const BYTE *)&byteorderpixel) == image->image_byte_order)
	*((CARD32 *)addr) = pixel;
      else
#endif
	if (image->image_byte_order == MSBFirst)
	  {
	    addr[0] = pixel >> 24;
	    addr[1] = pixel >> 16;
	    addr[2] = pixel >> 8;
	    addr[3] = pixel;
	  }
	else
	  {
	    addr[3] = pixel >> 24;
	    addr[2] = pixel >> 16;
	    addr[1] = pixel >> 8;
	    addr[0] = pixel;
	  }
      return 1;
    }
  else
    {
      return xcb_put_pixel_generic(image, x, y, pixel);
    }
}

static int
xcb_put_pixel16 (XCBImage *image, int x, int y, CARD32 pixel)
{
  CARD8 *addr;

  if ((image->format == ZPixmap) && 
      (image->bits_per_pixel == 16))
    {
      addr = &((CARD8 *)image->data)
	[y * image->bytes_per_line + (x << 1)];
      if (image->image_byte_order == MSBFirst)
	{
	  addr[0] = pixel >> 8;
	  addr[1] = pixel;
	}
      else
	{
	  addr[1] = pixel >> 8;
	  addr[0] = pixel;
	}
      return 1;
    }
  else
    {
      return xcb_put_pixel_generic(image, x, y, pixel);
    }
}

static int
xcb_put_pixel8 (XCBImage *image, int x, int y, CARD32 pixel)
{
  if ((image->format == ZPixmap) &&
      (image->bits_per_pixel == 8))
    {
      image->data[y * image->bytes_per_line + x] = pixel;
      return 1;
    }
  else
    {
      return xcb_put_pixel_generic(image, x, y, pixel);
    }
}

static int
xcb_put_pixel1 (XCBImage *image, int x, int y, CARD32 pixel)
{
  CARD8 bit;
  int xoff;
  int yoff;

  if (((image->bits_per_pixel | image->depth) == 1) &&
      (image->image_byte_order == image->bitmap_format_bit_order))
    {
      xoff = x + image->xoffset;
      yoff = y * image->bytes_per_line + (xoff >> 3);
      xoff &= 7;
      if (image->bitmap_format_bit_order == MSBFirst)
	bit = 0x80 >> xoff;
      else
	bit = 1 << xoff;
      if (pixel & 1)
	image->data[yoff] |= bit;
      else
	image->data[yoff] &= ~bit;
      return 1;
    }
  else
    {
      return xcb_put_pixel_generic(image, x, y, pixel);
    }
}


/* GetPixel */

static unsigned long const low_bits_table[] = {
    0x00000000, 0x00000001, 0x00000003, 0x00000007,
    0x0000000f, 0x0000001f, 0x0000003f, 0x0000007f,
    0x000000ff, 0x000001ff, 0x000003ff, 0x000007ff,
    0x00000fff, 0x00001fff, 0x00003fff, 0x00007fff,
    0x0000ffff, 0x0001ffff, 0x0003ffff, 0x0007ffff,
    0x000fffff, 0x001fffff, 0x003fffff, 0x007fffff,
    0x00ffffff, 0x01ffffff, 0x03ffffff, 0x07ffffff,
    0x0fffffff, 0x1fffffff, 0x3fffffff, 0x7fffffff,
    0xffffffff
};

static CARD32
xcb_get_pixel_generic (XCBImage *image,
		       int       x,
		       int       y)
{
  CARD32         pixel;
  CARD32         px;
  register BYTE *src;
  register BYTE *dst;
  register int i, j;
  int bits, nbytes;
  INT32 plane;
  
  if ((image->bits_per_pixel | image->depth) == 1)
    {
      src = &image->data[XYINDEX(x, y, image)];
      dst = (BYTE *)&pixel;
      pixel = 0;
      for (i = image->bitmap_format_scanline_unit >> 3; --i >= 0; )
	*dst++ = *src++;
      XYNORMALIZE(&pixel, image);
      bits = (x + image->xoffset) % image->bitmap_format_scanline_unit;
      pixel = ((((BYTE *)&pixel)[bits>>3])>>(bits&7)) & 1;
    }
  else
    if (image->format == XYPixmap)
      {
	pixel = 0;
	plane = 0;
	nbytes = image->bitmap_format_scanline_unit >> 3;
	for (i = image->depth ; --i >= 0 ; )
	  {
	    src = &image->data[XYINDEX(x, y, image)+ plane];
	    dst = (BYTE *)&px;
	    px = 0;
	    for (j = nbytes ; --j >= 0 ; )
	      *dst++ = *src++;
	    XYNORMALIZE(&px, image);
	    bits = (x + image->xoffset) % image->bitmap_format_scanline_unit;
	    pixel = (pixel << 1) |
	      (((((BYTE *)&px)[bits>>3])>>(bits&7)) & 1);
	    plane = plane + (image->bytes_per_line * image->height);
	  }
      }
  else
    if (image->format == ZPixmap)
      {
	src = &image->data[ZINDEX(x, y, image)];
	dst = (BYTE *)&px;
	px = 0;
	for (i = (image->bits_per_pixel + 7) >> 3 ; --i >= 0 ; )
	  *dst++ = *src++;		
	ZNORMALIZE(&px, image);
	pixel = 0;
	for (i = sizeof(CARD32) ; --i >= 0 ; )
	  pixel = (pixel << 8) | ((CARD8 *)&px)[i];
	if (image->bits_per_pixel == 4)
	  {
	    if (x & 1)
	      pixel >>= 4;
	    else
	      pixel &= 0xf;
	  }
      }
    else
      {
	return 0; /* bad image */
      }
  if (image->bits_per_pixel == image->depth)
    return pixel;
  else
    return (pixel & low_bits_table[image->depth]);
}

static CARD32
xcb_get_pixel32 (XCBImage *image,
		 int       x,
		 int       y)
{
  register CARD8 *addr;
  CARD32          pixel;
  
  if ((image->format == ZPixmap) &&
      (image->bits_per_pixel == 32))
    {
      addr = &((CARD8 *)image->data)
	[y * image->bytes_per_line + (x << 2)];
#ifndef WORD64
      if (*((const BYTE *)&byteorderpixel) == image->image_byte_order)
	pixel = *((CARD32 *)addr);
      else
#endif
	if (image->image_byte_order == MSBFirst)
	  pixel = ((CARD32)addr[0] << 24 |
		   (CARD32)addr[1] << 16 |
		   (CARD32)addr[2] << 8  |
		   (CARD32)addr[3]);
	else
	  pixel = ((CARD32)addr[3] << 24 |
		   (CARD32)addr[2] << 16 |
		   (CARD32)addr[1] << 8  |
		   (CARD32)addr[0]);
      if (image->depth != 32)
	pixel &= low_bits_table[image->depth];
      return pixel;
    }
  else
    {
      return xcb_get_pixel_generic (image, x, y);
    }
}

static CARD32
xcb_get_pixel16 (XCBImage *image,
		 int       x,
		 int       y)
{
  register CARD8 *addr;
  CARD32          pixel;
  
  if ((image->format == ZPixmap) &&
      (image->bits_per_pixel == 16))
    {
      addr = &((CARD8 *)image->data)
	[y * image->bytes_per_line + (x << 1)];
      if (image->image_byte_order == MSBFirst)
	pixel = addr[0] << 8 | addr[1];
      else
	pixel = addr[1] << 8 | addr[0];
      if (image->depth != 16)
	pixel &= low_bits_table[image->depth];
      return pixel;
    }
  else
    {
    return xcb_get_pixel_generic (image, x, y);
  }
}

static CARD32
xcb_get_pixel8 (XCBImage *image,
		int       x,
		int       y)
{
  CARD8 pixel;
  
  if ((image->format == ZPixmap) &&
      (image->bits_per_pixel == 8))
    {
      pixel = ((CARD8 *)image->data)
	[y * image->bytes_per_line + x];
      if (image->depth != 8)
	pixel &= low_bits_table[image->depth];
      return pixel;
    }
  else
    {
      return xcb_get_pixel_generic (image, x, y);
    }
}

static CARD32
xcb_get_pixel1 (XCBImage *image,
		int       x,
		int       y)
{
  unsigned char bit;
  int xoff, yoff;
  
  if (((image->bits_per_pixel | image->depth) == 1) &&
      (image->image_byte_order == image->bitmap_format_bit_order))
    {
    xoff = x + image->xoffset;
    yoff = y * image->bytes_per_line + (xoff >> 3);
    xoff &= 7;
    if (image->bitmap_format_bit_order == MSBFirst)
      bit = 0x80 >> xoff;
    else
      bit = 1 << xoff;
    return (image->data[yoff] & bit) ? 1 : 0;
  }
  else
    {
      return xcb_get_pixel_generic (image, x, y);
    }
}
