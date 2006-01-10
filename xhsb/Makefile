XCB_CFLAGS = -lXCB

all: XProto.glue.o
	ghc --make $(XCB_CFLAGS) -o Main Main $^

%.glue.o: %.glue.c %.glue.h
	ghc -c $<

clean:
	-rm -f *.o *.hi Main
