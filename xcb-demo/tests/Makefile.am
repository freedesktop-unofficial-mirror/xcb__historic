
MAINTAINERCLEANFILES = Makefile.in

INCLUDES = $(XCBAUX_CFLAGS) $(XCBIMAGE_CFLAGS)

bin_PROGRAMS = julia lissajoux

julia_LDADD = $(XCBAUX_LIBS) $(XCBIMAGE_LIBS)
julia_SOURCES = julia.c

lissajoux_LDADD = $(XCBAUX_LIBS) $(XCBIMAGE_LIBS) -lm
lissajoux_SOURCES =lissajoux.c
