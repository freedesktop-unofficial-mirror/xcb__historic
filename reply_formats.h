#ifndef REPLY_FORMATS_H
#define REPLY_FORMATS_H

#include "xp_core.h"

int formatGetWindowAttributesReply(Window wid, xGetWindowAttributesReply *reply);
int formatGetGeometryReply(Window wid, xGetGeometryReply *reply);
int formatQueryTreeReply(Window wid, xQueryTreeReply *reply);
int formatEvent(XCB_Event *e);

#endif /* REPLY_FORMATS_H */
