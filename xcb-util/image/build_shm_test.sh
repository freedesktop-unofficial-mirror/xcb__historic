gcc -g -O2 -Wall -c `pkg-config --cflags xcb` -o xcb_image.o xcb_image.c
gcc -g -O2 -Wall `pkg-config --cflags --libs xcb` -o test_xcb_image_shm xcb_image.o test_xcb_image_shm.c