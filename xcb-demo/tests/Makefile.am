INCLUDES = $(XCBIMAGE_CFLAGS)

bin_PROGRAMS = julia lissajoux

julia_LDADD = $(XCBIMAGE_LIBS)
julia_SOURCES = julia.c

lissajoux_LDADD = $(XCBIMAGE_LIBS) -lm
lissajoux_SOURCES =lissajoux.c
