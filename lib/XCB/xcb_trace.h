#ifndef __XCB_TRACE_H
#define __XCB_TRACE_H

#ifndef XCBTRACEREQ
#define XCBTRACEREQ 0
#endif

#ifndef XCBTRACEREP
#define XCBTRACEREP 0
#endif

#ifndef XCBTRACEEVENT
#define XCBTRACEEVENT 0
#endif

#if XCBTRACEREQ || XCBTRACEREP || XCBTRACEEVENT
#include <stdio.h>
#endif

#if XCBTRACEREP
#define XCBREPTRACER(id) fputs(id " reply wait\n", stderr);
#else
#define XCBREPTRACER(id)
#endif

#if XCBTRACEREQ
#define XCBREQTRACER(id) fputs(id " request send\n", stderr);
#else
#define XCBREQTRACER(id)
#endif

#endif