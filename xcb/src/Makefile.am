lib_LTLIBRARIES = libXCB.la

M4FLAGS = $(XCBPROTO_CFLAGS)

EXTHEADERS = \
		extensions/bigreq.h \
		extensions/shm.h \
		extensions/shape.h \
		extensions/render.h \
		extensions/dpms.h \
		extensions/sync.h \
		extensions/xc_misc.h
EXTSOURCES = \
		extensions/bigreq.c \
		extensions/shm.c \
		extensions/shape.c \
		extensions/render.c \
		extensions/dpms.c \
		extensions/sync.c \
		extensions/xc_misc.c
EXTENSIONS = $(EXTSOURCES) $(EXTHEADERS)

COREPROTO = xcb.h xproto.c xcb_types.c

xcbinclude_HEADERS = xcb.h xcbint.h client-c.xcb $(EXTHEADERS)

CFLAGS =
AM_CFLAGS = -include config.h $(CDEBUGFLAGS) $(XCBPROTO_CFLAGS) $(XPROTO_CFLAGS) $(XAU_CFLAGS)
libXCB_la_LIBADD = $(XCBPROTO_LIBS) $(XPROTO_LIBS) $(XAU_LIBS)
libXCB_la_SOURCES = \
		xcb_conn.c xcb_out.c xcb_in.c xcb_ext.c xcb_xid.c \
		xcb_list.c xcb_util.c xcb_auth.c xcb_des.c \
		$(COREPROTO) $(EXTENSIONS)

xcb_des.c:
	touch xcb_des.c

BUILT_SOURCES = $(COREPROTO) $(EXTENSIONS)
CLEANFILES = $(COREPROTO) $(EXTENSIONS)
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
