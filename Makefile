CFLAGS = -Wall -g

all: main

main: main.o xcb_conn.o xp_core.o
main.o xp_core.o: xcb_conn.h xp_core.h
xcb_conn.o: xcb_conn.h

%.h: %.m4 xcb_types.m4f xcbgen_h.m4 xcbgen.m4
	m4 -R xcb_types.m4f xcbgen_h.m4 $*.m4 > $*.h
%.c: %.m4 xcb_types.m4f xcbgen_c.m4 xcbgen.m4
	m4 -R xcb_types.m4f xcbgen_c.m4 $*.m4 > $*.c

%.m4f: %.m4 xcbgen_h.m4 xcbgen.m4
	m4 -F $*.m4f xcbgen_h.m4 $*.m4 > /dev/null

clean:
	-rm -f main *.o core *.m4f xcb_conn.[ch] xp_core.[ch]

.PHONY: all clean
