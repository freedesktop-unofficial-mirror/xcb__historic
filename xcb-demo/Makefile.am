SUBDIRS = tests

EXTRA_DIST = autogen.sh

INCLUDES = $(XCB_CFLAGS)
LDADD = $(XCB_LIBS)

bin_PROGRAMS = hypnomoire xdpyinfo xcb-test dpms rendertest xcbrandr

hypnomoire_LDADD = $(LDADD) -lm -lpthread
hypnomoire_SOURCES = hypnomoire.c reply_formats.c

xdpyinfo_SOURCES = xdpyinfo.c

xcb_test_LDADD = $(LDADD) -lpthread
xcb_test_SOURCES = main.c reply_formats.c

dpms_SOURCES = dpms.c

rendertest_SOURCES = rendertest.c

xcbrandr_SOURCES = xcbrandr.c
