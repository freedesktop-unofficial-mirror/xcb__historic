/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <X11/XCB/xcb.h>
#include <X11/XCB/dpms.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

void check_dpms_version(XCBConnection *);
void check_dpms_capable(XCBConnection *);
void print_dpms_timeouts(XCBConnection *);

int main(int argc, char **argv)
{
	XCBConnection *c = XCBConnectBasic();
	/*XCB_DPMS_Init(c);*/
	check_dpms_version(c);
	check_dpms_capable(c);

	print_dpms_timeouts(c);

	exit(0);
	/*NOTREACHED*/
}

void check_dpms_version(XCBConnection *c)
{
	XCBDPMSGetVersionCookie cookie = XCBDPMSGetVersion(c, 1, 1);
	XCBDPMSGetVersionRep *ver = XCBDPMSGetVersionReply(c, cookie, 0);
	assert(ver);
	assert(ver->server_major_version == 1);
	assert(ver->server_minor_version == 1);
	free(ver);
}

void check_dpms_capable(XCBConnection *c)
{
	XCBDPMSCapableCookie cookie = XCBDPMSCapable(c);
	XCBDPMSCapableRep *cap = XCBDPMSCapableReply(c, cookie, 0);
	assert(cap);
	assert(cap->capable);
	free(cap);
}

void print_dpms_timeouts(XCBConnection *c)
{
	XCBDPMSGetTimeoutsCookie cookie = XCBDPMSGetTimeouts(c);
	XCBDPMSGetTimeoutsRep *time = XCBDPMSGetTimeoutsReply(c, cookie, 0);
	assert(time);
	printf("Standby: %d\n" "Suspend: %d\n" "Off: %d\n",
		time->standby_timeout, time->suspend_timeout, time->off_timeout);
	free(time);
}
