#include <X11/XCB/xcb.h>
#include <stdio.h>

XCBConnection *c;

void print_setup();
void print_formats();
void list_extensions(void (*)(int, char *));
void print_extension(int, char *);
void query_extension(int, char *);
void list_screens();
void print_screen(SCREEN *s);

int main(int argc, char **argv)
{
    void (*ext_printer)(int, char *) = print_extension;

    c = XCBConnectBasic();
    if(!c)
    {
	fputs("Connect failed.\n", stderr);
	exit(1);
    }

    for(--argc; argc; --argc)
	if(!strcmp(argv[argc], "-queryExtensions"))
	    ext_printer = query_extension;

    // "name of display:    %s" "\n"
    print_setup(c);
    // "\n" "focus:  window 0x%x, revert to %s" (e.g. PointerRoot)
    list_extensions(ext_printer);
    // "\n" "default screen number:    %d"
    list_screens();
    fputs("\n", stdout);

    exit(0);
}

void print_setup()
{
    printf("version number:    %d.%d", c->setup->protocol_major_version, c->setup->protocol_minor_version);
    fputs("\n" "vendor string:    ", stdout);
    fwrite(XCBConnSetupSuccessRepvendor(c->setup), 1, XCBConnSetupSuccessRepvendorLength(c->setup), stdout);
    printf("\n" "vendor release number:    %d", c->setup->release_number);
    // "\n" "XFree86 version: %d.%d.%d.%d"
    printf("\n" "maximum request size:  %d bytes", c->setup->maximum_request_length * 4);
    printf("\n" "motion buffer size:  %d", c->setup->motion_buffer_size);
    printf("\n" "bitmap unit, bit order, padding:    %d, %s, %d", c->setup->bitmap_format_scanline_unit, (c->setup->bitmap_format_bit_order == LSBFirst) ? "LSBFirst" : "MSBFirst", c->setup->bitmap_format_scanline_pad);
    printf("\n" "image byte order:    %s", (c->setup->image_byte_order == LSBFirst) ? "LSBFirst" : "MSBFirst");

    print_formats();

    printf("\n" "keycode range:    minimum %d, maximum %d", c->setup->min_keycode.id, c->setup->max_keycode.id);
}

void print_formats()
{
    int i = XCBConnSetupSuccessReppixmap_formatsLength(c->setup);
    FORMAT *p = XCBConnSetupSuccessReppixmap_formats(c->setup);
    printf("\n" "number of supported pixmap formats:    %d", i);
    fputs("\n" "supported pixmap formats:", stdout);
    for(--i; i >= 0; --i, ++p)
	printf("\n" "    depth %d, bits_per_pixel %d, scanline_pad %d", p->depth, p->bits_per_pixel, p->scanline_pad);
}

void list_extensions(void (*ext_printer)(int, char *))
{
    XCBListExtensionsRep *r;
    STRIter i;

    r = XCBListExtensionsReply(c, XCBListExtensions(c), 0);
    if(!r)
    {
	fputs("ListExtensions failed.\n", stderr);
	return;
    }

    i = XCBListExtensionsnames(r);
    printf("\n" "number of extensions:    %d", i.rem);
    for(; i.rem; STRNext(&i))
    {
	fputs("\n" "    ", stdout);
	ext_printer(STRnameLength(i.data), STRname(i.data));
    }
}

void print_extension(int len, char *name)
{
    fwrite(name, 1, len, stdout);
}

void query_extension(int len, char *name)
{
    XCBQueryExtensionRep *r;
    int comma = 0;

    r = XCBQueryExtensionReply(c, XCBQueryExtension(c, len, name), 0);
    if(!r)
    {
	fputs("QueryExtension failed.\n", stderr);
	return;
    }

    print_extension(len, name);
    fputs("  (", stdout);
    if(r->major_opcode)
    {
	printf("opcode: %d", r->major_opcode);
	comma = 1;
    }
    if(r->first_event)
    {
	if(comma)
	    fputs(", ", stdout);
	printf("base event: %d", r->first_event);
	comma = 1;
    }
    if(r->first_error)
    {
	if(comma)
	    fputs(", ", stdout);
	printf("base error: %d", r->first_error);
    }
    fputs(")", stdout);
}

void list_screens()
{
    SCREENIter i;
    int cur;

    i = XCBConnSetupSuccessReproots(c->setup);
    printf("\n" "number of screens:    %d" "\n", i.rem);
    for(cur = 1; i.rem; SCREENNext(&i), ++cur)
    {
	printf("\n" "screen #%d:", cur);
	print_screen(i.data);
    }
}

void print_screen(SCREEN *s)
{
    printf("\n" "  dimensions:    %dx%d pixels (%dx%d millimeters)", s->width_in_pixels, s->height_in_pixels, s->width_in_millimeters, s->height_in_millimeters);
}
