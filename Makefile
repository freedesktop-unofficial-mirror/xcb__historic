CFLAGS = -Wall -g
LDFLAGS = -lpthread

all: main

main: main.o reply_formats.o xcb_conn.o xp_core.o
main.o reply_formats.o xp_core.o: xcb_conn.h xp_core.h
xcb_conn.o: xcb_conn.h

sources: xcb_conn.h xcb_conn.c xp_core.h xp_core.c

%.h: %.m4 xcbgen.m4
	m4 -D"_H" xcbgen.m4 $*.m4 > $*.h
%.c: %.m4 xcbgen.m4
	m4 -D"_C" xcbgen.m4 $*.m4 > $*.c

clean:
	-rm -f main *.o core xcb_conn.[ch] xp_core.[ch]

.PHONY: all sources clean
