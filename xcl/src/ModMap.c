/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

XModifierKeymap *XGetModifierMapping(Display *dpy)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGetModifierMappingRep *r;
    XModifierKeymap *res;
    unsigned int nbytes;

    res = (XModifierKeymap *) Xmalloc(sizeof (XModifierKeymap));
    if (!res)
	return 0;

    r = XCBGetModifierMappingReply(c, XCBGetModifierMapping(c), 0);
    if (!r)
	goto error;

    nbytes = XCBGetModifierMappingkeycodesLength(r);
    res->modifiermap = (KeyCode *) Xmalloc (nbytes);
    if (!res->modifiermap)
	goto error;

    memcpy(res->modifiermap, XCBGetModifierMappingkeycodes(r), nbytes);
    res->max_keypermod = r->keycodes_per_modifier;

done:
    return res;

error:
    if (res)
	Xfree(res);
    res = 0;
    goto done;
}

/*
 *	Returns:
 *	0	Success
 *	1	Busy - one or more old or new modifiers are down
 *	2	Failed - one or more new modifiers unacceptable
 */
int XSetModifierMapping(register Display *dpy, register XModifierKeymap *modmap)
{
    XCBSetModifierMappingCookie c;
    XCBSetModifierMappingRep *r;
    int ret = 0;

    c = XCBSetModifierMapping(XCBConnectionOfDisplay(dpy), modmap->max_keypermod, (KEYCODE *) modmap->modifiermap);
    r = XCBSetModifierMappingReply(XCBConnectionOfDisplay(dpy), c, 0);
    if (r)
	ret = r->status;
    free(r);
    return ret;
}

XModifierKeymap *XNewModifiermap(int keyspermodifier)
{
    XModifierKeymap *res;

    res = (XModifierKeymap *) Xmalloc((sizeof (XModifierKeymap)));
    if (!res)
	return 0;

    res->max_keypermod = keyspermodifier;
    res->modifiermap = 0;
    if (keyspermodifier <= 0)
	return res;

    res->modifiermap = (KeyCode *) Xmalloc((unsigned) (8 * keyspermodifier));
    if (!res->modifiermap) {
	    Xfree((char *) res);
	    return 0;
    }
    return res;
}

int
XFreeModifiermap(map)
    XModifierKeymap *map;
{
    if (map) {
	if (map->modifiermap)
	    Xfree((char *) map->modifiermap);
	Xfree((char *) map);
    }
    return 1;
}

#if NeedFunctionPrototypes
XModifierKeymap *
XInsertModifiermapEntry(XModifierKeymap *map,
#if NeedWidePrototypes
			unsigned int keycode,
#else
			KeyCode keycode,
#endif
			int modifier)
#else
XModifierKeymap *
XInsertModifiermapEntry(map, keycode, modifier)
    XModifierKeymap *map;
    KeyCode keycode;
    int modifier;
#endif
{
    XModifierKeymap *newmap;
    int i,
	row = modifier * map->max_keypermod,
	newrow,
	lastrow;

    for (i=0; i<map->max_keypermod; i++) {
        if (map->modifiermap[ row+i ] == keycode)
	    return(map); /* already in the map */
        if (map->modifiermap[ row+i ] == 0) {
            map->modifiermap[ row+i ] = keycode;
	    return(map); /* we added it without stretching the map */
	}
    }   

    /* stretch the map */
    if ((newmap = XNewModifiermap(map->max_keypermod+1)) == NULL)
	return (XModifierKeymap *) NULL;
    newrow = row = 0;
    lastrow = newmap->max_keypermod * 8;
    while (newrow < lastrow) {
	for (i=0; i<map->max_keypermod; i++)
	    newmap->modifiermap[ newrow+i ] = map->modifiermap[ row+i ];
	newmap->modifiermap[ newrow+i ] = 0;
	row += map->max_keypermod;
	newrow += newmap->max_keypermod;
    }
    (void) XFreeModifiermap(map);
    newrow = newmap->max_keypermod * modifier + newmap->max_keypermod - 1;
    newmap->modifiermap[ newrow ] = keycode;
    return(newmap);
}

#if NeedFunctionPrototypes
XModifierKeymap *
XDeleteModifiermapEntry(XModifierKeymap *map,
#if NeedWidePrototypes
			unsigned int keycode,
#else
			KeyCode keycode,
#endif
			int modifier)
#else
XModifierKeymap *
XDeleteModifiermapEntry(map, keycode, modifier)
    XModifierKeymap *map;
    KeyCode keycode;
    int modifier;
#endif
{
    int i,
	row = modifier * map->max_keypermod;

    for (i=0; i<map->max_keypermod; i++) {
        if (map->modifiermap[ row+i ] == keycode)
            map->modifiermap[ row+i ] = 0;
    }
    /* should we shrink the map?? */
    return (map);
}
