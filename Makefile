CFLAGS = -Wall -g
LDFLAGS = -lpthread
M4 = m4

OBJS = main.o reply_formats.o xcb_conn.o xp_core.o

.SUFFIXES: .m4

.m4.h:
	$(M4) -D"_H" xcbgen.m4 $*.m4 > $*.h

.m4.c:
	$(M4) -D"_C" xcbgen.m4 $*.m4 > $*.c

all: main

main: $(OBJS) xp_core.h
	$(CC) $(CFLAGS) -o main $(OBJS) $(LDFLAGS)

main.o reply_formats.o xp_core.o: xcb_conn.h xp_core.h
xcb_conn.o: xcb_conn.h

xcb_conn.c xcb_conn.h: xcb_conn.m4 xcbgen.m4

xp_core.c xp_core.h: xp_core.m4 xcbgen.m4

sources: xcb_conn.h xcb_conn.c xp_core.h xp_core.c

clean:
	-rm -f main *.o core xcb_conn.[ch] xp_core.[ch]

.PHONY: all sources clean
