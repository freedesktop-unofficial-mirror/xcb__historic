
AUTOMAKE_OPTIONS = foreign

SUFFIXES = .m4

.m4.h:
	$(M4) -D"_H" xcbgen.m4 $*.m4 > $*.h

.m4.c:
	$(M4) -D"_C" xcbgen.m4 $*.m4 > $*.c

lib_LTLIBRARIES = libxcb.la
libxcb_la_SOURCES = xcb_conn.c xp_core.c xcb_conn.h xp_core.h
libxcb_la_DEPENDENCIES = xcb_conn.m4 xp_core.m4 xcbgen.m4

xp_core.lo: xcb_conn.h xp_core.h
xcb_conn.lo: xcb_conn.h
xcb_conn.c xcb_conn.h: xcb_conn.m4 xcbgen.m4
xp_core.c xp_core.h: xp_core.m4 xcbgen.m4

clean-local:
	-rm -f xcb_conn.c xcb_conn.h xp_core.c xp_core.h

sources: xcb_conn.h xcb_conn.c xp_core.h xp_core.c

bin_PROGRAMS = main hypnomoire
main_SOURCES = main.c reply_formats.c reply_formats.h
main_LDADD = libxcb.la
main_LDFLAGS = -lpthread

hypnomoire_SOURCES = hypnomoire.c reply_formats.c reply_formats.h
hypnomoire_LDADD = libxcb.la
hypnomoire_LDFLAGS = -lm -lpthread

main.o reply_formats.o hypnomoire.o: xcb_conn.h xp_core.h
