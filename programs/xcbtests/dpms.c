/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <xcb.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

void check_dpms_version(XCB_Connection *);
void check_dpms_capable(XCB_Connection *);
void print_dpms_timeouts(XCB_Connection *);

int main(int argc, char **argv)
{
	XCB_Connection *c = XCB_Connect_Basic();
	/*XCB_DPMS_Init(c);*/
	check_dpms_version(c);
	check_dpms_capable(c);

	print_dpms_timeouts(c);

	exit(0);
	/*NOTREACHED*/
}

void check_dpms_version(XCB_Connection *c)
{
	XCB_DPMSGetVersion_cookie cookie = XCB_DPMSGetVersion(c, 1, 1);
	XCB_DPMSGetVersion_Rep *ver = XCB_DPMSGetVersion_Reply(c, cookie, 0);
	assert(ver);
	assert(ver->server_major_version == 1);
	assert(ver->server_minor_version == 1);
	free(ver);
}

void check_dpms_capable(XCB_Connection *c)
{
	XCB_DPMSCapable_cookie cookie = XCB_DPMSCapable(c);
	XCB_DPMSCapable_Rep *cap = XCB_DPMSCapable_Reply(c, cookie, 0);
	assert(cap);
	assert(cap->capable);
	free(cap);
}

void print_dpms_timeouts(XCB_Connection *c)
{
	XCB_DPMSGetTimeouts_cookie cookie = XCB_DPMSGetTimeouts(c);
	XCB_DPMSGetTimeouts_Rep *time = XCB_DPMSGetTimeouts_Reply(c, cookie, 0);
	assert(time);
	printf("Standby: %d\n" "Suspend: %d\n" "Off: %d\n",
		time->standby_timeout, time->suspend_timeout, time->off_timeout);
	free(time);
}
