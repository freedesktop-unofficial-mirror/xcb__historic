dnl Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
dnl All Rights Reserved.  See the file COPYING for licensing information.
/*
 * This file automatically generated by xcbwrap.m4.
 * Edit at your peril.
 */

#include "xclint.h"
divert(-1) dnl kill output until the next diversion

dnl default values
define(`DEFRETTYPE', `int')
define(`DEFRETVAL', `1')
define(`DEFPARAMS', `')
define(`DEFFLUSHGC', `')
define(`DEFALLOC', `')

dnl init to defaults
define(`RETTYPE', DEFRETTYPE)
define(`RETVAL', DEFRETVAL)
define(`PARAMS', DEFPARAMS)
define(`FLUSHGC', DEFFLUSHGC)
define(`ALLOC', DEFALLOC)

dnl XCLREQ(name, specs ...)
define(`XCLREQ', `
dnl evaluate anything that the caller passed in
shift($@)

dnl save values into their per-request storage
define(`$1'`RETTYPE', RETTYPE)
define(`$1'`RETVAL', RETVAL)
define(`$1'`PARAMS', defn(`PARAMS'))
define(`$1'`FLUSHGC', FLUSHGC)
define(`$1'`ALLOC', ALLOC)

dnl restore defaults for next round
define(`RETTYPE', DEFRETTYPE)
define(`RETVAL', DEFRETVAL)
define(`PARAMS', DEFPARAMS)
define(`FLUSHGC', DEFFLUSHGC)
define(`ALLOC', DEFALLOC)
')

define(`XCLRETTYPE', `define(`RETTYPE', `$1')')
define(`XCLRETVAL', `define(`RETVAL', `$1')')
define(`XCLPARAMS', `define(`PARAMS', `,$@')')
define(`XCLGC', `define(`FLUSHGC', `$1')')

define(`XCLALLOC', `define(`ALLOC', `
	$1 $2 = XCB`'dnl
ifelse($1, `Window', `WINDOW',
ifelse($1, `Pixmap', `PIXMAP',
ifelse($1, `Cursor', `CURSOR',
ifelse($1, `Font', `FONT',
ifelse($1, `GContext', `GCONTEXT',
ifelse($1, `Colormap', `COLORMAP',
ifelse($1, `Atom', `ATOM')))))))`'dnl
New(c).xid;')
define(`RETTYPE', `$1')
define(`RETVAL', `$2')
')


dnl Implementations of XCB request description macros

define(`VOIDREQUEST', `divert(0)ifdef(`$1'`RETTYPE', `
$1RETTYPE X`'$1(Display *dpy`'$1PARAMS)
{
	register XCBConnection *c = XCBConnectionOfDisplay(dpy);dnl
$1ALLOC
ifelse($1FLUSHGC, , , `dnl
	LockDisplay(dpy);
	FlushGC(dpy, $1FLUSHGC);
')dnl
	XCB$1(c`'divert(-1)
	$2
	divert(0));
ifelse($1FLUSHGC, , , `dnl
	UnlockDisplay(dpy);
')dnl
	return $1RETVAL;
}
')divert(-1)')

define(`PARAM', `divert(0), dnl
ifelse($1, `WINDOW', `XCLWINDOW($2)',
ifelse($1, `PIXMAP', `XCLPIXMAP($2)',
ifelse($1, `CURSOR', `XCLCURSOR($2)',
ifelse($1, `FONT', `XCLFONT($2)',
ifelse($1, `GCONTEXT', `XCLGCONTEXT($2->gid)',
ifelse($1, `COLORMAP', `XCLCOLORMAP($2)',
ifelse($1, `ATOM', `XCLATOM($2)',
ifelse($1, `DRAWABLE', `XCLDRAWABLE($2)',
ifelse($1, `FONTABLE', `XCLFONTABLE($2)',
ifelse($1, `VISUALID', `XCLVISUALID($2 == CopyFromParent ? CopyFromParent : $2->visualid)',
ifelse($1, `TIMESTAMP', `XCLTIMESTAMP($2)',
ifelse($1, `KEYSYM', `XCLKEYSYM($2)',
ifelse($1, `KEYCODE', `XCLKEYCODE($2)',
ifelse($1, `BUTTON', `XCLBUTTON($2)',
`$2'))))))))))))))`'dnl
divert(-1)')

define(`LOCALPARAM', `
PARAM($1, $2)
')

define(`LISTPARAM', `divert(0), dnl
($1 *) $2`'dnl
divert(-1)')

define(`VALUEPARAM', `
PARAM($1, $2)
LISTPARAM(CARD32, $3)
')
