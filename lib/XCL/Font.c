/* Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.
 * Portions Copyright 1986, 1998  The Open Group
 * Copyright (c) 2000  The XFree86 Project, Inc.
 * 
 * See the file COPYING for licensing information. */
#include "xclint.h"

#if defined(XF86BIGFONT) && !defined(MUSTCOPY)
#define USE_XF86BIGFONT
#endif
#ifdef USE_XF86BIGFONT
#include <sys/types.h>
#ifdef HAS_SHM
#include <sys/ipc.h>
#include <sys/shm.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <X11/extensions/xf86bigfstr.h>
#endif

#ifdef USE_LOCALE
#include "Xlcint.h"
#include "XlcPubI.h"
#endif


#ifdef USE_XF86BIGFONT

/* Private data for this extension. */
typedef struct {
    XExtCodes *codes;
    CARD32 serverSignature;
    CARD32 serverCapabilities;
} XF86BigfontCodes;

/* Additional bit masks that can be set in serverCapabilities */
#define CAP_VerifiedLocal 256

static XF86BigfontCodes *_XF86BigfontCodes(
#if NeedFunctionPrototypes
    Display*		/* dpy */
#endif
);

static XFontStruct *_XF86BigfontQueryFont(
#if NeedFunctionPrototypes
    Display*		/* dpy */,
    XF86BigfontCodes*	/* extcodes */,
    Font		/* fid */,
#endif
);

void _XF86BigfontFreeFontMetrics(
#if NeedFunctionPrototypes
    XFontStruct*	/* fs */
#endif
);

#endif /* USE_XF86BIGFONT */


#if NeedFunctionPrototypes
XFontStruct *XLoadQueryFont(
   register Display *dpy,
   _Xconst char *name)
#else
XFontStruct *XLoadQueryFont(dpy, name)
   register Display *dpy;
   char *name;
#endif
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

static int
_XCopyFontProps (fs, src, i)
    register XFontStruct *fs;
    register FONTPROP *src;
    register int i;
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

static void _XCopyCharInfo(register XCharStruct *dst, register CHARINFO *src)
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

static int
_XCopyCharInfos (fs, src, i)
    register XFontStruct *fs;
    register CHARINFO *src;
    register int i;
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

#ifdef USE_XF86BIGFONT
static int
_XCopyBigfontCharInfos (fs, src, src_len, map, i)
    register XFontStruct *fs;
    register CHARINFO *src;
    register int src_len;
    register CARD16 *map;
    register int i;
{
    if (i > 0) {
	register XCharStruct *dst;
	dst = (XCharStruct *) Xmalloc (i * sizeof(*dst));
	fs->per_char = dst;
	if (!dst)
	    return 0;

	/* must always copy for this request */
	for (; i; --i, ++dst, ++map) {
	    if (*map >= src_len) {
		fprintf(stderr, "_XF86BigfontQueryFont: server returned wrong data\n");
		goto error;
	    }
	    _XCopyCharInfo (dst, src[*map]);
	}
    }
    else
	fs->per_char = NULL;

    return 1;
}
#endif

XFontStruct *XQueryFont(dpy, fid)
    register Display *dpy;
    Font fid;
{
    register XFontStruct *fs = 0;
    register _XExtension *ext;

    XCBQueryFontCookie c;
    XCBQueryFontRep *r = 0;

    LockDisplay(dpy);

#ifdef USE_XF86BIGFONT
    fs = _XF86BigfontQueryFont(dpy, fid);
    if (fs)
	goto done;
#endif

    c = XCBQueryFont(XCBConnectionOfDisplay(dpy), XCLFONTABLE(fid));
    r = XCBQueryFontReply(XCBConnectionOfDisplay(dpy), c, 0);
    /* Xlib supresses BadFont error messages here, but I can't be arsed. */
    if (!r)
	goto error;

    fs = (XFontStruct *) Xmalloc (sizeof (XFontStruct));
    if (!fs)
	goto error;

    if (!_XCopyFontProps (fs, XCBQueryFontproperties(r), r->properties_len))
	goto error;
    if (!_XCopyCharInfos (fs, XCBQueryFontchar_infos(r), r->char_infos_len))
	goto error;
    _XCopyCharInfo (&fs->min_bounds, &r->min_bounds);
    _XCopyCharInfo (&fs->max_bounds, &r->max_bounds);

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
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->create_Font) (*ext->create_Font)(dpy, fs, &ext->codes);

done:
    free(r);
    UnlockDisplay(dpy);
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

static int
_XFreeFontStruct(dpy, fs)
    register Display *dpy;
    XFontStruct *fs;
{ 
    if (fs->per_char) {
#ifdef USE_XF86BIGFONT
	_XF86BigfontFreeFontMetrics(fs);
#else
	Xfree ((char *) fs->per_char);
#endif
    }
    _XFreeExtData(fs->ext_data);
    if (fs->properties)
	Xfree ((char *) fs->properties);
    Xfree ((char *) fs);
    return 1;
}

int
XFreeFont(dpy, fs)
    register Display *dpy;
    XFontStruct *fs;
{ 
    register _XExtension *ext;
    FONT f = { fs->fid };

    LockDisplay(dpy);
    /* call out to any extensions interested */
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->free_Font) (*ext->free_Font)(dpy, fs, &ext->codes);
    XCBCloseFont(XCBConnectionOfDisplay(dpy), f);
    UnlockDisplay(dpy);
    return _XFreeFontStruct(dpy, fs);
}

#ifdef USE_XF86BIGFONT

/* Magic cookie for finding the right XExtData structure on the display's
   extension list. */
static int XF86BigfontNumber = 1040697125;

static int
_XF86BigfontFreeCodes (extension)
    XExtData *extension;
{
    /* Don't Xfree(extension->private_data) because it is on the same malloc
       chunk as extension. */
    /* Don't Xfree(extension->private_data->codes) because this is shared with
       the display's ext_procs list. */
    return 0;
}

static XF86BigfontCodes *
_XF86BigfontCodes (dpy)
    register Display *dpy;
{
    XEDataObject dpy_union;
    XExtData *pData;
    XF86BigfontCodes *pCodes;
    char *envval;

    dpy_union.display = dpy;

    /* If the server is known to support the XF86Bigfont extension,
     * return the extension codes. If the server is known to not support
     * the extension, don't bother checking again.
     */
    pData = XFindOnExtensionList(XEHeadOfExtensionList(dpy_union),
				 XF86BigfontNumber);
    if (pData)
	return (XF86BigfontCodes *) pData->private_data;

    pData = (XExtData *) Xmalloc(sizeof(XExtData) + sizeof(XF86BigfontCodes));
    if (!pData) {
	/* Out of luck. */
	return (XF86BigfontCodes *) NULL;
    }

    /* See if the server supports the XF86Bigfont extension. */
    envval = getenv("XF86BIGFONT_DISABLE"); /* Let the user disable it. */
    if (envval != NULL && envval[0] != '\0')
	pCodes = NULL;
    else {
	XExtCodes *codes = XInitExtension(dpy, XF86BIGFONTNAME);
	if (codes == NULL)
	    pCodes = NULL;
	else {
	    pCodes = (XF86BigfontCodes *) &pData[1];
	    pCodes->codes = codes;
	}
    }
    pData->number = XF86BigfontNumber;
    pData->private_data = (XPointer) pCodes;
    pData->free_private = _XF86BigfontFreeCodes;
    XAddToExtensionList(XEHeadOfExtensionList(dpy_union), pData);
    if (pCodes) {
	/* See if the server supports the XF86BigfontQueryFont request. */
	XCBXF86BigfontQueryVersionCookie c;
	XCBXF86BigfontQueryVersionRep *r;

	c = XCBXF86BigfontQueryVersion(XCBConnectionOfDisplay(dpy));
	r = XCBXF86BigfontQueryVersionReply(XCBConnectionOfDisplay(dpy), c, 0);
	if(!r)
	    goto ignore_extension;

	/* No need to provide backward compatibility with version 1.0. It
	   was never widely distributed. */
	if (r->major_version < 1 || (r->major_version == 1 && r->minor_version < 1))
	    goto ignore_extension;

	pCodes->serverSignature = reply.signature;
	pCodes->serverCapabilities = reply.capabilities;
    }
    return pCodes;

  ignore_extension:
    /* No need to Xfree(pCodes) or Xfree(pCodes->codes), see
       _XF86BigfontFreeCodes comment. */
    pCodes = (XF86BigfontCodes *) NULL;
    pData->private_data = (XPointer) pCodes;
    return pCodes;
}

static int
_XF86BigfontFreeNop (extension)
    XExtData *extension;
{
    return 0;
}

static XFontStruct *
_XF86BigfontQueryFont (dpy, fid)
    register Display *dpy;
    Font fid;
{
    register XFontStruct *fs = 0;
    register _XExtension *ext;
    FONT f = { fid };
    XCBXF86BigfontQueryFontCookie c;
    XCBXF86BigfontQueryFontRep *r = 0;
    XCBQueryExtensionRep *extdata;
#ifdef HAS_SHM
    char *addr = 0;
#endif

    /* check whether the extension is present in the server */
    extdata = XCBXF86BigfontInit(XCBConnectionOfDisplay(dpy));
    if (!extdata->present)
	goto error;

    /* FIXME: must store extension capabilities somewhere */
    c = XCBXF86BigfontQueryFont(XCBConnectionOfDisplay(dpy), f, /* (extcodes->serverCapabilities & XF86Bigfont_CAP_LocalShm ? XF86Bigfont_FLAGS_Shm : 0) */);
    r = XCBXF86BigfontQueryFont(XCBConnectionOfDisplay(dpy), c, 0);
    /* Xlib kills BadFont errors from QueryFont, but I can't be arsed. */
    if (!r)
	goto error;

    fs = (XFontStruct *) Xmalloc (sizeof (XFontStruct));
    if (!fs)
	goto error;

    if (!_XCopyFontProps (fs, XCBQueryFontproperties(r), r->properties_len))
	goto error;

    if (reply.shmid == (CARD32)(-1)) {
	/* reply didn't use shared memory, copy from the wire. */
	if (!_XCopyBigfontCharInfos (fs, XCBXF86BigfontQueryFontunique_char_infos(r), r->unique_char_infos_len, XCBXF86BigfontQueryFontQueryFontchar_infos(r), r->char_infos_len))
	    goto error;
    } else {
	/* reply used shared memory, copy from there. */
#ifdef HAS_SHM
	struct shmid_ds buf;
	/* In some cases (e.g. an ssh daemon forwarding an X session to
	   a remote machine) it is possible that the X server thinks we
	   are running on the same machine (because getpeername() and
	   LocalClient() cannot know about the forwarding) but we are
	   not really local. Therefore, when we attach the first shared
	   memory segment, we verify that we are on the same machine as
	   the X server by checking that 1. shmat() succeeds, 2. the
	   segment has a sufficient size, 3. it contains the X server's
	   signature. */

	addr = shmat(reply.shmid, 0, SHM_RDONLY);
	if (addr == (char *)-1) {
	    fprintf(stderr, "_XF86BigfontQueryFont: could not attach shm segment\n");
	    goto noshm;
	}
	if (shmctl(reply.shmid, IPC_STAT, &buf) < 0)
	    goto noshm;
	if (buf.shm_segsz < reply.shmsegoffset + reply.nCharInfos * sizeof(XCharStruct) + sizeof(CARD32))
	    goto noshm;
	if (*(CARD32 *)(addr + reply.shmsegoffset + reply.nCharInfos * sizeof(XCharStruct)) != extcodes->serverSignature)
	    goto noshm;

	if (!_XCopyCharInfos (fs, addr + r->shmsegoffset, r->char_infos_len))
	    goto error;
#else /* shared memory not enabled: */
	fprintf(stderr, "_XF86BigfontQueryFont: try recompiling libX11 with HasShm, Xserver has shm support\n");
	goto noshm;
#endif
    }

    _XCopyCharInfo (fs->min_bounds, r->minBounds);
    _XCopyCharInfo (fs->max_bounds, r->maxBounds);

    fs->ext_data 		= NULL;
    fs->fid 			= fid;
    /* These fields of XFontStruct are defined in an entirely different order
     * than they appear in the protocol, so they can't be copied or aliased. */
    fs->direction 		= r->drawDirection;
    fs->min_char_or_byte2	= r->minCharOrByte2;
    fs->max_char_or_byte2 	= r->maxCharOrByte2;
    fs->min_byte1 		= r->minByte1;
    fs->max_byte1 		= r->maxByte1;
    fs->default_char 		= r->defaultChar;
    fs->all_chars_exist 	= r->allCharsExist;
    fs->ascent 			= cvtINT16toInt (r->fontAscent);
    fs->descent 		= cvtINT16toInt (r->fontDescent);
    
    /* call out to any extensions interested */
    for (ext = dpy->ext_procs; ext; ext = ext->next)
	if (ext->create_Font) (*ext->create_Font)(dpy, fs, &ext->codes);

done:
    free(r);
    return fs;

#ifdef HAS_SHM
noshm:
    /* Stop requesting shared memory transport from now on. */
    extcodes->serverCapabilities &= ~ XF86Bigfont_CAP_LocalShm;
#endif

error:
#ifdef HAS_SHM
    if (addr) shmdt(addr);
#endif
    if (fs) {
	if (fs->properties) Xfree((char *) fs->properties);
	if (fs->per_char) Xfree((char *) fs->per_char);
	Xfree((char *) fs);
	fs = 0;
    }
    goto done;
}

void
_XF86BigfontFreeFontMetrics (fs)
    XFontStruct *fs;
{
#ifdef HAS_SHM
    XExtData *pData;
    XEDataObject fs_union;

    fs_union.font = fs;
    if ((pData = XFindOnExtensionList(XEHeadOfExtensionList(fs_union),
				      XF86BigfontNumber)))
	shmdt ((char *) pData->private_data);
    else
	Xfree ((char *) fs->per_char);
#else
    Xfree ((char *) fs->per_char);
#endif
}

#endif /* USE_XF86BIGFONT */

static inline char *
_XIsValidLocaleName (name)
    char *name;
{
    char *p;
    if (!name)
	return 0;
    p = strrchr(name, '-');
    if (p == 0 || p == name || p[1] == 0 || (p[1] == '*' && p[2] == 0))
	return 0;
    return p;
}

#ifdef USE_LOCALE
#if NeedFunctionPrototypes
int _XF86LoadQueryLocaleFont(
    Display *dpy,
    _Xconst char *name,
    XFontStruct **xfp,
    Font *fidp)
#else
int _XF86LoadQueryLocaleFont(dpy, name)
    Display *dpy;
    char *name;
    XFontStruct **xfp;
    Font *fidp;
#endif
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
