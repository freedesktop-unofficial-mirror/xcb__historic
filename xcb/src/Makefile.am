lib_LTLIBRARIES = libXCB.la libXCBext.la

M4FLAGS = $(XCBPROTO_CFLAGS)

COREPROTO = xcb.c xcb.h xcb_types.c xcb_types.h

xcbinclude_HEADERS = xcb.h xcb_types.h xcb_conn.h xcb_event.h xcb_extension.h xcb_list.h macros-c.m4 macros-xcb.m4

libXCB_la_CFLAGS = $(XCBPROTO_CFLAGS) $(XPROTO_CFLAGS) $(XAU_CFLAGS)
libXCB_la_LIBADD = $(XCBPROTO_LIBS) $(XPROTO_LIBS) $(XAU_LIBS)
libXCB_la_SOURCES = \
		xcb_conn.c xcb_conn.h \
		xcb_event.c xcb_event.h \
		xcb_extension.c xcb_extension.h \
		xcb_io.c xcb_io.h \
		xcb_list.c xcb_list.h \
		$(COREPROTO)

libXCBext_la_CFLAGS = $(XCBPROTO_CFLAGS)
libXCBext_la_LIBADD = $(XCBPROTO_LIBS)
libXCBext_la_SOURCES = \
		extensions/shm.c extensions/shm.h \
		extensions/shape.c extensions/shape.h \
		extensions/render.c extensions/render.h \
		extensions/dpms.c extensions/dpms.h

BUILT_SOURCES = $(COREPROTO) $(libXCBext_la_SOURCES) X11
CLEANFILES = $(COREPROTO) $(libXCBext_la_SOURCES)
X11:
	mkdir X11
	ln -s `pwd` X11/XCB
clean-local:
	-rm -f X11/XCB
	rmdir extensions X11 || true

vpath %.xcb $(XCBPROTO_VPATH)
%.c %.h: %.xcb
	@n=`dirname $*`; test -d $$n || (echo mkdir $$n; mkdir $$n)
	$(M4) -D_H $(M4FLAGS) generics.xcb macros-c.m4 macros-xcb.m4 $< > $*.h
	$(M4) -D_C $(M4FLAGS) generics.xcb macros-c.m4 macros-xcb.m4 $< > $*.c
