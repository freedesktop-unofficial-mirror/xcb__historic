/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * Copyright (c) 2000  The XFree86 Project, Inc.
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

#ifdef USE_LOCALE
#include "Xlcint.h"
#include "XlcPubI.h"
#endif


XFontStruct *XLoadQueryFont(Display *dpy, const char *name)
{
#ifdef USE_LOCALE
    XFontStruct *font_result;
#endif
    FONT f;

#ifdef USE_LOCALE
    if (_XF86LoadQueryLocaleFont(dpy, name, &font_result, (Font *)0))
	return font_result;
#endif

    f = XCBFONTNew(XCBConnectionOfDisplay(dpy));
    XCBOpenFont(XCBConnectionOfDisplay(dpy), f, strlen(name), name);

    /* Xlib kills BadName errors from OpenFont, but I can't be arsed. */
    return XQueryFont(dpy, f.xid);
}

static int _XCopyFontProps(XFontStruct *fs, FONTPROP *src, int i)
{
    fs->n_properties = i;
    if (i > 0) {
	fs->properties = (XFontProp *) Xmalloc (i * sizeof(XFontProp));
	if (!fs->properties)
	    return 0;
	memcpy(fs->properties, src, i * sizeof(*src));
    }
    else
	fs->properties = NULL;

    return 1;
}

static void _XCopyCharInfo(XCharStruct *dst, CHARINFO *src)
{
#ifdef MUSTCOPY
    dst->lbearing = cvtINT16toShort(src->leftSideBearing);
    dst->rbearing = cvtINT16toShort(src->rightSideBearing);
    dst->width = cvtINT16toShort(src->characterWidth);
    dst->ascent = cvtINT16toShort(src->ascent);
    dst->descent = cvtINT16toShort(src->descent);
    dst->attributes = src->attributes;
#else
    /* XXX: this won't work if short isn't 16 bits */
    *dst = * (XCharStruct *) src;
#endif
}

static int _XCopyCharInfos(XFontStruct *fs, CHARINFO *src, register int i)
{
    if (i > 0) {
	register XCharStruct *dst;
	dst = (XCharStruct *) Xmalloc (i * sizeof(*dst));
	fs->per_char = dst;
	if (!dst)
	    return 0;

#ifdef MUSTCOPY
	for (; i; --i, ++dst, ++src)
	    _XCopyCharInfo (dst, src);
#else
	memcpy(dst, src, i * sizeof(*src));
#endif
    }
    else
	fs->per_char = NULL;

    return 1;
}

XFontStruct *XQueryFont(Display *dpy, Font fid)
{
    XFontStruct *fs = 0;
    _XExtension *ext;

    XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBQueryFontRep *r;

    r = XCBQueryFontReply(c, XCBQueryFont(c, XCLFONTABLE(fid)), 0);
    /* Xlib supresses BadFont error messages here, but I can't be arsed. */
    if (!r)
	goto error;

    fs = (XFontStruct *) Xmalloc (sizeof (XFontStruct));
    if(!fs)
	goto error;

    if(!_XCopyFontProps(fs, XCBQueryFontproperties(r), XCBQueryFontpropertiesLength(r)))
	goto error;
    if(!_XCopyCharInfos(fs, XCBQueryFontchar_infos(r), XCBQueryFontchar_infosLength(r)))
	goto error;
    _XCopyCharInfo(&fs->min_bounds, &r->min_bounds);
    _XCopyCharInfo(&fs->max_bounds, &r->max_bounds);

    fs->ext_data 		= NULL;
    fs->fid 			= fid;
    /* These fields of XFontStruct are defined in an entirely different order
     * than they appear in the protocol, so they can't be copied or aliased. */
    fs->direction 		= r->draw_direction;
    fs->min_char_or_byte2	= r->min_char_or_byte2;
    fs->max_char_or_byte2 	= r->max_char_or_byte2;
    fs->min_byte1 		= r->min_byte1;
    fs->max_byte1 		= r->max_byte1;
    fs->default_char 		= r->default_char;
    fs->all_chars_exist 	= r->all_chars_exist;
    fs->ascent 			= cvtINT16toInt (r->font_ascent);
    fs->descent 		= cvtINT16toInt (r->font_descent);
    
    /* call out to any extensions interested */
    LockDisplay(dpy);
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->create_Font) (*ext->create_Font)(dpy, fs, &ext->codes);
    UnlockDisplay(dpy);

done:
    free(r);
    return fs;

error:
    if (fs) {
	if (fs->properties) Xfree((char *) fs->properties);
	if (fs->per_char) Xfree((char *) fs->per_char);
	Xfree((char *) fs);
	fs = 0;
    }
    goto done;
}

static inline int _XFreeFontStruct(XFontStruct *fs)
{ 
    if(fs->per_char)
	Xfree(fs->per_char);
    _XFreeExtData(fs->ext_data);
    if(fs->properties)
	Xfree(fs->properties);
    Xfree(fs);
    return 1;
}

int XFreeFont(Display *dpy, XFontStruct *fs)
{ 
    _XExtension *ext;

    /* call out to any extensions interested */
    LockDisplay(dpy);
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->free_Font) (*ext->free_Font)(dpy, fs, &ext->codes);
    UnlockDisplay(dpy);
    XCBCloseFont(XCBConnectionOfDisplay(dpy), XCLFONT(fs->fid));
    return _XFreeFontStruct(fs);
}

#ifdef USE_LOCALE
static inline char *_XIsValidLocaleName(char *name)
{
    char *p;
    if(!name)
	return 0;
    p = strrchr(name, '-');
    if(p == 0 || p == name || p[1] == 0 || (p[1] == '*' && p[2] == 0))
	return 0;
    return p;
}

int _XF86LoadQueryLocaleFont(Display *dpy, const char *name, XFontStruct **xfp, Font *fidp)
{
    int l;
    char *charset, *p;
    char buf[256];
    FONT f;
    XLCd lcd;

    /* no font without a name. */
    if (!name)
	return 0;

    /* doing nothing is easily accomplished successfully. */
    /* XXX: Xlib only returns 1 here if the font can be opened and queried. */
    if (!xfp && !fidp)
	return 1;

    /* the name must end in "-*", or else it's not our job. */
    l = strlen(name);
    if (l < 2 || strcmp(name + l - 2, "-*"))
	return 0;

    /* find out which locale is preferred; pick a default if not sure. */
    charset = 0;
    /* next three lines stolen from _XkbGetCharset() */
    lcd = _XlcCurrentLC();
    if (lcd)
	charset = XLC_PUBLIC(lcd, encoding_name);

    p = _XIsValidLocaleName (charset);
    if (!p) {
	/* prefer latin1 if no encoding found */
	charset = "ISO8859-1";
	p = charset + 7;
    }

    /* the name must be at least as long as the locale, aside from anything
     * following the last hyphen in either. */
    if (l - 2 - (p - charset) < 0)
	return 0;

    /* if the locale in the name has nothing to do with the preferred locale,
     * it's not our job after all. */
    if (strncasecmp(name + l - 2 - (p - charset), charset, p - charset))
	return 0;

    /* if we're about to overrun our buffer, give up. */
    if (strlen(p + 1) + l - 1 >= sizeof(buf) - 1)
	return 0;

    /* copy the name into our buffer, but replace the asterisk with the end
     * of the preferred locale name. */
    strcpy(buf, name);
    strcpy(buf + l - 1, p + 1);

    /* load the font with the new name and get information about it. */
    f = XCBFONTNew(XCBConnectionOfDisplay(dpy));
    XCBOpenFont(XCBConnectionOfDisplay(dpy), f, buf);

    /* invariant, established earlier: at least one of fidp and xfp is valid.
     * as a result, this function never closes the font. */
    
    /* give the caller the font id if they asked for it. */
    if (fidp)
	*fidp = f.xid;

    /* give the caller the FontStruct if they asked for it. */
    /* XXX: Xlib only returns 1 here if the font can be opened and queried. */
    if (!xfp)
	return 1;

    *xfp = XQueryFont(dpy, f.xid);
    return *xfp;
}
#endif
