
AUTOMAKE_OPTIONS = foreign

SUFFIXES = .m4 .c .h

.m4.h:
	$(M4) -D"_H" xcbgen.m4 $*.m4 > $*.h

.m4.c:
	$(M4) -D"_C" xcbgen.m4 $*.m4 > $*.c

lib_LTLIBRARIES = libxcb.la libxcb_dpms.la libxcb_shape.la

libxcb_la_SOURCES = xcb_conn.c xp_core.c xcb_conn.h xp_core.h
libxcb_la_DEPENDENCIES = xcb_conn.m4 xp_core.m4 xcbgen.m4

libxcb_dpms_la_SOURCES = xcb_dpms.c xcb_dpms.h
libxcb_dpms_la_DEPENDENCIES = xcb_dpms.m4

libxcb_shape_la_SOURCES = xcb_shape.c xcb_shape.h
libxcb_shape_la_DEPENDENCIES = xcb_shape.m4

GENSOURCES = $(libxcb_la_SOURCES) $(libxcb_dpms_la_SOURCES) \
	$(libxcb_shape_la_SOURCES)
$(GENSOURCES): xcbgen.m4

xcb_conn.lo: xcb_conn.h
xp_core.lo: xp_core.h xcb_conn.h
xcb_dpms.lo: xcb_dpms.h xp_core.h xcb_conn.h
xcb_shape.lo: xcb_shape.h xp_core.h xcb_conn.h

clean-local:
	-rm -f $(GENSOURCES)

sources: $(GENSOURCES)

bin_PROGRAMS = main hypnomoire dpms

main_SOURCES = main.c reply_formats.c reply_formats.h
main_LDADD = libxcb.la
main_LDFLAGS = -lpthread

hypnomoire_SOURCES = hypnomoire.c reply_formats.c reply_formats.h
hypnomoire_LDADD = libxcb.la
hypnomoire_LDFLAGS = -lm -lpthread

dpms_SOURCES = dpms.c
dpms_LDADD = libxcb.la libxcb_dpms.la

main.o reply_formats.o hypnomoire.o dpms.o: xcb_conn.h xp_core.h
