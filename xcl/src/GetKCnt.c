/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

int XGetKeyboardControl(Display *dpy, register XKeyboardState *state)
{
	XCBConnection *c = XCBConnectionOfDisplay(dpy);
	XCBGetKeyboardControlRep *r;

	r = XCBGetKeyboardControlReply(c, XCBGetKeyboardControl(c), 0);
	/* error check: Xlib doesn't check this */
	if(!r)
		return 0;

	state->global_auto_repeat = r->global_auto_repeat;
	state->led_mask = r->led_mask;
	state->key_click_percent = r->key_click_percent;
	state->bell_percent = r->bell_percent;
	state->bell_pitch = r->bell_pitch;
	state->bell_duration = r->bell_duration;
	memcpy(state->auto_repeats, r->auto_repeats, sizeof state->auto_repeats);
	free(r);
	return 1;
}
