#ifndef ICCCM_H
#define ICCCM_H

#include <X11/XCB/xcb.h>
#include "xcb_property.h"

/* WM_NAME */

void SetWMName(XCBConnection *c, XCBWINDOW window, XCBATOM encoding, CARD32 name_len, const char *name);
int GetWMName(XCBConnection *c, XCBWINDOW window, CARD8 *format, XCBATOM *encoding, CARD32 *name_len, char **name);
void WatchWMName(PropertyHandlers *prophs, CARD32 long_len, GenericPropertyHandler handler, void *data);

/* WM_ICON_NAME */

void SetWMIconName(XCBConnection *c, XCBWINDOW window, XCBATOM encoding, CARD32 name_len, const char *name);
void WatchWMIconName(PropertyHandlers *prophs, CARD32 long_len, GenericPropertyHandler handler, void *data);

/* WM_SIZE_HINTS */

typedef struct SizeHints SizeHints;
SizeHints *AllocSizeHints();
void FreeSizeHints(SizeHints *hints);

void SizeHintsSetPosition(SizeHints *hints, int user_specified, INT32 x, INT32 y);
void SizeHintsSetSize(SizeHints *hints, int user_specified, INT32 width, INT32 height);
void SizeHintsSetMinSize(SizeHints *hints, INT32 min_width, INT32 min_height);
void SizeHintsSetMaxSize(SizeHints *hints, INT32 max_width, INT32 max_height);
void SizeHintsSetResizeInc(SizeHints *hints, INT32 width_inc, INT32 height_inc);
void SizeHintsSetAspect(SizeHints *hints, INT32 min_aspect_num, INT32 min_aspect_den, INT32 max_aspect_num, INT32 max_aspect_den);
void SizeHintsSetBaseSize(SizeHints *hints, INT32 base_width, INT32 base_height);
void SizeHintsSetWinGravity(SizeHints *hints, CARD8 win_gravity);

void SetWMSizeHints(XCBConnection *c, XCBWINDOW window, XCBATOM property, SizeHints *hints);

/* WM_NORMAL_HINTS */

void SetWMNormalHints(XCBConnection *c, XCBWINDOW window, SizeHints *hints);

/* WM_PROTOCOLS */

void SetWMProtocols(XCBConnection *c, XCBWINDOW window, CARD32 list_len, XCBATOM *list);

#define HAS_DISCRIMINATED_NAME 0
#if HAS_DISCRIMINATED_NAME
char *DiscriminatedAtomNameByScreen(const char *base, CARD8 screen);
char *DiscriminatedAtomNameByResource(const char *base, CARD32 resource);
char *DiscriminatedAtomNameUnique(const char *base, CARD32 id);
#endif

#endif /* ICCCM_H */
