CFLAGS = -Wall -g

all: main

main: main.o xp_core.o
main.o xp_core.o: xp_core.h

xp_core.h: xcbgen_h.m4 xp_core.m4
	m4 xcbgen_h.m4 xp_core.m4 > xp_core.h
xp_core.c: xcbgen_c.m4 xp_core.m4
	m4 xcbgen_c.m4 xp_core.m4 > xp_core.c

xcbgen_h.m4 xcbgen_c.m4: xcbgen.m4

clean:
	-rm -f main *.o core xp_core.h xp_core.c

.PHONY: all clean
