
MAINTAINERCLEANFILES = Makefile.in

lib_LTLIBRARIES = libXCBConvenient.la

xcbinclude_HEADERS = xcb_convenient.h

AM_CFLAGS = -Wall
INCLUDES = $(XCB_CFLAGS)
LDADD = $(XCB_LIBS)

libXCBConvenient_la_SOURCES = xcb_convenient.c

pkgconfig_DATA = xcb-convenient.pc

EXTRA_DIST=xcb-convenient.pc.in
