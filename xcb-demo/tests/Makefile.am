
MAINTAINERCLEANFILES = Makefile.in

INCLUDES = $(XCBCONV_CFLAGS) $(XCBIMAGE_CFLAGS)

bin_PROGRAMS = julia lissajoux

julia_LDADD = $(XCBCONV_LIBS) $(XCBIMAGE_LIBS)
julia_SOURCES = julia.c

lissajoux_LDADD = $(XCBCONV_LIBS) $(XCBIMAGE_LIBS) -lm
lissajoux_SOURCES =lissajoux.c
