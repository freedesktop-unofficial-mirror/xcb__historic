#include <stdlib.h>
#include <string.h>
#include "xcb_icccm.h"
#include "xcb_atom.h"

/* WM_NAME */

void SetWMName(XCBConnection *c, XCBWINDOW window, XCBATOM encoding, CARD32 name_len, const char *name)
{
	XCBChangeProperty(c, PropModeReplace, window, WM_NAME, encoding, 8, name_len, name);
}

int GetWMName(XCBConnection *c, XCBWINDOW window, CARD8 *format, XCBATOM *encoding, CARD32 *name_len, char **name)
{
	XCBGetPropertyCookie cookie;
	XCBGetPropertyRep *reply;
	cookie = GetAnyProperty(c, 0, window, WM_NAME, 128);
	reply = XCBGetPropertyReply(c, cookie, 0);
	if(!reply)
		return 0;
	*format = reply->format;
	*encoding = reply->type;
	*name_len = XCBGetPropertyValueLength(reply) * *format / 8;
	if(reply->bytes_after)
	{
		cookie = XCBGetProperty(c, 0, window, WM_NAME, reply->type, 0, *name_len);
		free(reply);
		reply = XCBGetPropertyReply(c, cookie, 0);
		if(!reply)
			return 0;
	}
	memmove(reply, XCBGetPropertyValue(reply), *name_len);
	*name = (char *) reply;
	return 1;
}

void WatchWMName(PropertyHandlers *prophs, CARD32 long_len, GenericPropertyHandler handler, void *data)
{
	SetPropertyHandler(prophs, WM_NAME, long_len, handler, data);
}

/* WM_ICON_NAME */

void SetWMIconName(XCBConnection *c, XCBWINDOW window, XCBATOM encoding, CARD32 name_len, const char *name)
{
	XCBChangeProperty(c, PropModeReplace, window, WM_ICON_NAME, encoding, 8, name_len, name);
}

void WatchWMIconName(PropertyHandlers *prophs, CARD32 long_len, GenericPropertyHandler handler, void *data)
{
	SetPropertyHandler(prophs, WM_ICON_NAME, long_len, handler, data);
}

/* WM_SIZE_HINTS */

typedef enum {
	USPosition = 1 << 0,
	USSize = 1 << 1,
	PPosition = 1 << 2,
	PSize = 1 << 3,
	PMinSize = 1 << 4,
	PMaxSize = 1 << 5,
	PResizeInc = 1 << 6,
	PAspect = 1 << 7,
	PBaseSize = 1 << 8,
	PWinGravity = 1 << 9
} SizeHintsFlags;

struct SizeHints {
	CARD32 flags;
	INT32 x, y, width, height;
	INT32 min_width, min_height;
	INT32 max_width, max_height;
	INT32 width_inc, height_inc;
	INT32 min_aspect_num, min_aspect_den;
	INT32 max_aspect_num, max_aspect_den;
	INT32 base_width, base_height;
	CARD32 win_gravity;
};

SizeHints *AllocSizeHints()
{
	return calloc(1, sizeof(SizeHints));
}

void FreeSizeHints(SizeHints *hints)
{
	free(hints);
}

void SizeHintsSetPosition(SizeHints *hints, int user_specified, INT32 x, INT32 y)
{
	hints->flags &= ~(USPosition | PPosition);
	if(user_specified)
		hints->flags |= USPosition;
	else
		hints->flags |= PPosition;
	hints->x = x;
	hints->y = y;
}

void SizeHintsSetSize(SizeHints *hints, int user_specified, INT32 width, INT32 height)
{
	hints->flags &= ~(USSize | PSize);
	if(user_specified)
		hints->flags |= USSize;
	else
		hints->flags |= PSize;
	hints->width = width;
	hints->height = height;
}

void SizeHintsSetMinSize(SizeHints *hints, INT32 min_width, INT32 min_height)
{
	hints->flags |= PMinSize;
	hints->min_width = min_width;
	hints->min_height = min_height;
}

void SizeHintsSetMaxSize(SizeHints *hints, INT32 max_width, INT32 max_height)
{
	hints->flags |= PMaxSize;
	hints->max_width = max_width;
	hints->max_height = max_height;
}

void SizeHintsSetResizeInc(SizeHints *hints, INT32 width_inc, INT32 height_inc)
{
	hints->flags |= PResizeInc;
	hints->width_inc = width_inc;
	hints->height_inc = height_inc;
}

void SizeHintsSetAspect(SizeHints *hints, INT32 min_aspect_num, INT32 min_aspect_den, INT32 max_aspect_num, INT32 max_aspect_den)
{
	hints->flags |= PAspect;
	hints->min_aspect_num = min_aspect_num;
	hints->min_aspect_den = min_aspect_den;
	hints->max_aspect_num = max_aspect_num;
	hints->max_aspect_den = max_aspect_den;
}

void SizeHintsSetBaseSize(SizeHints *hints, INT32 base_width, INT32 base_height)
{
	hints->flags |= PBaseSize;
	hints->base_width = base_width;
	hints->base_height = base_height;
}

void SizeHintsSetWinGravity(SizeHints *hints, CARD8 win_gravity)
{
	hints->flags |= PWinGravity;
	hints->win_gravity = win_gravity;
}

void SetWMSizeHints(XCBConnection *c, XCBWINDOW window, XCBATOM property, SizeHints *hints)
{
	XCBChangeProperty(c, PropModeReplace, window, property, WM_SIZE_HINTS, 32, sizeof(*hints) / 4, hints);
}

/* WM_NORMAL_HINTS */

void SetWMNormalHints(XCBConnection *c, XCBWINDOW window, SizeHints *hints)
{
	SetWMSizeHints(c, window, WM_NORMAL_HINTS, hints);
}

/* WM_PROTOCOLS */

void SetWMProtocols(XCBConnection *c, XCBWINDOW window, CARD32 list_len, XCBATOM *list)
{
	InternAtomFastCookie proto;
	XCBATOM WM_PROTOCOLS;

	proto = InternAtomFast(c, 0, sizeof("WM_PROTOCOLS") - 1, "WM_PROTOCOLS");
	WM_PROTOCOLS = InternAtomFastReply(c, proto, 0);

	XCBChangeProperty(c, PropModeReplace, window, WM_PROTOCOLS, ATOM, 32, list_len, list);
}

#if HAS_DISCRIMINATED_NAME
#include <stdarg.h>
static char *makename(const char *fmt, ...)
{
	char *ret;
	int n;
	va_list ap;
	va_start(ap, fmt);
	n = vasprintf(&ret, fmt, ap);
	va_end(ap);
	if(n < 0)
		return 0;
	return ret;
}

char *DiscriminatedAtomNameByScreen(const char *base, CARD8 screen)
{
	return makename("%s_S%u", base, screen);
}

char *DiscriminatedAtomNameByResource(const char *base, CARD32 resource)
{
	return makename("%s_R%08X", base, resource);
}

char *DiscriminatedAtomNameUnique(const char *base, CARD32 id)
{
	if(base)
		return makename("%s_U%lu", base, id);
	else
		return makename("U%lu", id);
}
#endif
