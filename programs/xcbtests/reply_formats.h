#ifndef REPLY_FORMATS_H
#define REPLY_FORMATS_H

#include <client/xp_core.h>

int formatGetWindowAttributesReply(Window wid, XCB_GetWindowAttributes_Rep *reply);
int formatGetGeometryReply(Window wid, XCB_GetGeometry_Rep *reply);
int formatQueryTreeReply(Window wid, XCB_QueryTree_Rep *reply);
int formatEvent(XCB_Event *e);

#endif /* REPLY_FORMATS_H */
