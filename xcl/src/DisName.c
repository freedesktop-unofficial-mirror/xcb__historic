/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1994, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */

/* Returns the name of the display XOpenDisplay would use.  This is better
 * than just printing the "display" variable in a program because that
 * could be NULL and/or there could be an environment variable set.
 * This makes it easier for programmers to provide meaningful error
 * messages. 
 *
 * 
 * For example, this is used in XOpenDisplay() as
 *	strncpy( displaybuf, XDisplayName( display ), sizeof(displaybuf) );
 *      if ( *displaybuf == '\0' ) return( NULL );
 *  This check is actually unnecessary because the next thing is an index()
 *  call looking for a ':' which will fail and we'll return(NULL).
 */
/* Written at Waterloo - JMSellens */

#include <stdlib.h>

char *XDisplayName(char *display)
{
    char *d;
    if(display && *display != '\0')
	return display;
    d = getenv("DISPLAY");
    if(d)
	return d;
    return "";
}