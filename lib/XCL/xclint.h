/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * 
 * See the file COPYING for licensing information. */
#ifndef XCLINT_H
#define XCLINT_H

#include "xcl.h"

#define INT32 XlibINT32
#define INT16 XlibINT16
#define INT8 XlibINT8
#define CARD32 XlibCARD32
#define CARD16 XlibCARD16
#define CARD8 XlibCARD8
#define BITS32 XlibBITS32
#define BITS16 XlibBITS16
#define BYTE XlibBYTE
#define BOOL XlibBOOL
#define KEYCODE XlibKEYCODE

#include <X11/Xlibint.h>

#undef INT32
#undef INT16
#undef INT8
#undef CARD32
#undef CARD16
#undef CARD8
#undef BITS32
#undef BITS16
#undef BYTE
#undef BOOL
#undef KEYCODE

#endif /* XCLINT_H */
