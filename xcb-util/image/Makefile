CFLAGS = -g -O2 -Wall $(shell pkg-config --cflags xcb)
LDFLAGS = $(shell pkg-config --libs xcb)

all: test_xcb_image test_xcb_image_shm

test_xcb_image_shm: xcb_image.o
test_xcb_image: xcb_image.o
