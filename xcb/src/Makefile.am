lib_LTLIBRARIES = libXCB.la

M4FLAGS = $(XCBPROTO_CFLAGS)

COREPROTO = xcb.h xproto.c xcb_types.c

xcbinclude_HEADERS = xcb.h xcbint.h client-c.xcb

AM_CFLAGS = $(XCBPROTO_CFLAGS) $(XPROTO_CFLAGS) $(XAU_CFLAGS)
libXCB_la_LIBADD = $(XCBPROTO_LIBS) $(XPROTO_LIBS) $(XAU_LIBS)
libXCB_la_SOURCES = \
		xcb_conn.c xcb_auth.c xcb_io.c \
		xcb_list.c xcb_event.c \
		$(COREPROTO) \
		extensions/shm.c extensions/shm.h \
		extensions/shape.c extensions/shape.h \
		extensions/render.c extensions/render.h \
		extensions/dpms.c extensions/dpms.h

BUILT_SOURCES = $(COREPROTO) $(libXCBext_la_SOURCES)
CLEANFILES = $(COREPROTO) $(libXCBext_la_SOURCES)
clean-local:
	rmdir extensions || true

vpath %.xcb $(XCBPROTO_VPATH)
%.h: %.xcb generics.xcb client-c.xcb
	@n=`dirname $*`; test -d $$n || (echo mkdir $$n; mkdir $$n)
	$(M4) -D_H $(M4FLAGS) client-c.xcb $*.xcb > $*.h
%.c: %.xcb generics.xcb client-c.xcb
	@n=`dirname $*`; test -d $$n || (echo mkdir $$n; mkdir $$n)
	$(M4) -D_C $(M4FLAGS) client-c.xcb $*.xcb > $*.c

xcb.h: xcb.h.m4 generics.xcb client-c.xcb xcb_types.xcb xproto.xcb
	$(M4) $(M4FLAGS) xcb.h.m4 > xcb.h
