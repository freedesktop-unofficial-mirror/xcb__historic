XCLREQ(AllowEvents, XCLPARAMS(int mode, Time time))

XCLREQ(Bell, XCLPARAMS(int percent))

XCLREQ(SetAccessControl, XCLPARAMS(int mode))

XCLREQ(ChangeActivePointerGrab, XCLPARAMS(unsigned int event_mask, Cursor cursor, Time time))

XCLREQ(SetCloseDownMode, XCLPARAMS(int mode))

XCLREQ(ChangePointerControl, XCLPARAMS(Bool do_acceleration, Bool do_threshold, int acceleration_numerator, int acceleration_denominator, int threshold))

XCLREQ(ChangeSaveSet, XCLPARAMS(Window window, int mode))

XCLREQ(ClearArea, XCLPARAMS(Window window, int x, int y, unsigned int width, unsigned int height, Bool exposures))

XCLREQ(ConvertSelection, XCLPARAMS(Atom selection, Atom target, Atom property, Window requestor, Time time))

XCLREQ(CopyArea, XCLGC(gc), XCLPARAMS(Drawable src_drawable, Drawable dst_drawable, GC gc, int src_x, int src_y, unsigned int width, unsigned int height, int dst_x, int dst_y))

XCLREQ(CopyColormapAndFree, XCLALLOC(Colormap, mid), XCLPARAMS(Colormap src_cmap))

XCLREQ(CopyPlane, XCLGC(gc), XCLPARAMS(Drawable src_drawable, Drawable dst_drawable, GC gc, int src_x, int src_y, unsigned int width, unsigned int height, int dst_x, int dst_y, unsigned long bit_plane))

XCLREQ(CreateColormap, XCLALLOC(Colormap, mid), XCLPARAMS(Window window, Visual *visual, int alloc))

XCLREQ(CreatePixmap, XCLALLOC(Pixmap, pid), XCLPARAMS(Drawable drawable, unsigned int width, unsigned int height, unsigned int depth))

XCLREQ(DeleteProperty, XCLPARAMS(Window window, Atom property))

XCLREQ(DestroySubwindows, XCLPARAMS(Window window))

XCLREQ(DestroyWindow, XCLPARAMS(Window window))

XCLREQ(ForceScreenSaver, XCLPARAMS(int mode))

XCLREQ(FreeColormap, XCLPARAMS(Colormap cmap))

XCLREQ(FreeColors, XCLPARAMS(Colormap cmap, unsigned long *pixels, int pixels_len, unsigned long plane_mask))

XCLREQ(FreeCursor, XCLPARAMS(Cursor cursor))

XCLREQ(FreePixmap, XCLPARAMS(Pixmap pixmap))

XCLREQ(GrabButton, XCLPARAMS(unsigned int modifiers, unsigned int button, Window grab_window, Bool owner_events, unsigned int event_mask, int pointer_mode, int keyboard_mode, Window confine_to, Cursor cursor))

XCLREQ(GrabKey, XCLPARAMS(int key, unsigned int modifiers, Window grab_window, Bool owner_events, int pointer_mode, int keyboard_mode))

XCLREQ(GrabServer)

XCLREQ(InstallColormap, XCLPARAMS(Colormap cmap))

XCLREQ(KillClient, XCLPARAMS(XID resource))

XCLREQ(MapSubwindows, XCLPARAMS(Window window))

XCLREQ(MapWindow, XCLPARAMS(Window window))

XCLREQ(ReparentWindow, XCLPARAMS(Window window, Window parent, int x, int y))

XCLREQ(SetInputFocus, XCLPARAMS(Window focus, int revert_to, Time time))

XCLREQ(ChangeKeyboardMapping, XCLPARAMS(int first_keycode, int keysyms_per_keycode, KeySym *keysyms, int keycode_count))

XCLREQ(SetSelectionOwner, XCLPARAMS(Atom selection, Window owner, Time time))

XCLREQ(SetScreenSaver, XCLPARAMS(int timeout, int interval, int prefer_blanking, int allow_exposures))

XCLREQ(UngrabButton, XCLPARAMS(unsigned int button, unsigned int modifiers, Window grab_window))

XCLREQ(UngrabKeyboard, XCLPARAMS(Time time))

XCLREQ(UngrabKey, XCLPARAMS(int key, unsigned int modifiers, Window grab_window))

XCLREQ(UngrabPointer, XCLPARAMS(Time time))

XCLREQ(UngrabServer)

XCLREQ(UninstallColormap, XCLPARAMS(Colormap cmap))

XCLREQ(UnmapSubwindows, XCLPARAMS(Window window))

XCLREQ(UnmapWindow, XCLPARAMS(Window window))

XCLREQ(WarpPointer, XCLPARAMS(Window src_window, Window dst_window, int src_x, int src_y, unsigned int src_width, unsigned int src_height, int dst_x, int dst_y))

XCLREQ(UnloadFont, XCLCALL(CloseFont), XCLPARAMS(Font font))

XCLREQ(ResizeWindow, XCLCALL(ConfigureWindow), XCLPARAMS(Window window, unsigned int width, unsigned int height),
XCLLOCAL(`CARD16 value_mask = CWWidth | CWHeight'), XCLLOCAL(`CARD32 value_list[] = { width, height }'))

XCLREQ(MoveResizeWindow, XCLCALL(ConfigureWindow), XCLPARAMS(Window window, int x, int y, unsigned int width, unsigned int height),
XCLLOCAL(`CARD16 value_mask = CWX | CWY | CWWidth | CWHeight'), XCLLOCAL(`CARD32 value_list[] = { x, y, width, height }'))

XCLREQ(MoveWindow, XCLCALL(ConfigureWindow), XCLPARAMS(Window window, int x, int y),
XCLLOCAL(`CARD16 value_mask = CWX | CWY'), XCLLOCAL(`CARD32 value_list[] = { x, y }'))

XCLREQ(SetWindowBackground, XCLCALL(ChangeWindowAttributes), XCLPARAMS(Window window, unsigned long pixel),
XCLLOCAL(`CARD16 value_mask = CWBackPixel'), XCLLOCAL(`CARD32 value_list[] = { pixel }'))

XCLREQ(SetWindowBackgroundPixmap, XCLCALL(ChangeWindowAttributes), XCLPARAMS(Window window, Pixmap pixmap),
XCLLOCAL(`CARD16 value_mask = CWBackPixmap'), XCLLOCAL(`CARD32 value_list[] = { pixmap }'))

XCLREQ(DefineCursor, XCLCALL(ChangeWindowAttributes), XCLPARAMS(Window window, Cursor cursor),
XCLLOCAL(`CARD16 value_mask = CWCursor'), XCLLOCAL(`CARD32 value_list[] = { cursor }'))

XCLREQ(SelectInput, XCLCALL(ChangeWindowAttributes), XCLPARAMS(Window window, long mask),
XCLLOCAL(`CARD16 value_mask = XCBCWEventMask'), XCLLOCAL(`CARD32 value_list[] = { mask }'))

XCLREQ(ClearWindow, XCLCALL(ClearArea), XCLPARAMS(Window window),
XCLLOCAL(`BOOL exposures = 0'), XCLLOCAL(`INT16 x = 0, y = 0'), XCLLOCAL(`CARD16 width = 0, height = 0'))

XCLREQ(FillPolygon, XCLCALL(FillPoly), XCLGC(gc), XCLPARAMS(Drawable drawable, GC gc, XPoint *points, int points_len, int shape, int coordinate_mode))

XCLREQ(DrawLine, XCLCALL(PolySegment), XCLGC(gc), XCLPARAMS(Drawable drawable, GC gc, int x1, int y1, int x2, int y2),
XCLLOCAL(`CARD16 segments_len = 1'), XCLLOCAL(`SEGMENT segments[] = { { x1, y1, x2, y2 } }'))

XCLREQ(DrawPoint, XCLCALL(PolyPoint), XCLGC(gc), XCLPARAMS(Drawable drawable, GC gc, int x, int y),
XCLLOCAL(`BYTE coordinate_mode = CoordModeOrigin'), XCLLOCAL(`CARD16 points_len = 1'), XCLLOCAL(`POINT points[] = { { x, y } }'))
