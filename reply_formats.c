#include <stdio.h>
#include "reply_formats.h"

#define WINFMT "0x%08x"

int formatGetWindowAttributesReply(Window wid, xGetWindowAttributesReply *reply)
{
    if(!reply)
    {
        fprintf(stderr, "Failed to get attributes for window 0x%x.\n",
            (unsigned int) wid);
        return 0;
    }

    printf("Window " WINFMT " has attributes:\n"
           "    backingStore       = %d\n"
           "    visualID           = %#x\n"
           "    class              = %d\n"
           "    bitGravity         = %d\n"
           "    winGravity         = %d\n"
           "    backingBitPlanes   = 0x%08lx\n"
           "    backingPixel       = %ld\n"
           "    saveUnder          = %d\n"
           "    mapInstalled       = %d\n"
           "    mapState           = %d\n"
           "    override           = %d\n"
           "    colormap           = 0x%08x\n"
           "    allEventMasks      = 0x%08x\n"
           "    yourEventMask      = 0x%08x\n"
           "    doNotPropagateMask = 0x%08x\n",
        (unsigned int) wid,
        reply->backingStore,
        (unsigned int) reply->visualID,
        reply->class,
        reply->bitGravity,
        reply->winGravity,
        reply->backingBitPlanes,
        reply->backingPixel,
        reply->saveUnder,
        reply->mapInstalled,
        reply->mapState,
        reply->override,
        (unsigned int) reply->colormap,
        (unsigned int) reply->allEventMasks,
        (unsigned int) reply->yourEventMask,
        reply->doNotPropagateMask);

    fflush(stdout);
    return 1;
}

int formatGetGeometryReply(Window wid, xGetGeometryReply *reply)
{
    if(!reply)
    {
        fprintf(stderr, "Failed to get geometry for window " WINFMT ".\n",
            (unsigned int) wid);
        return 0;
    }

    printf("Geometry for window " WINFMT ": %dx%d%+d%+d\n",
        (unsigned int) wid,
        reply->width,
        reply->height,
        reply->x,
        reply->y);

    fflush(stdout);
    return 1;
}

int formatQueryTreeReply(Window wid, xQueryTreeReply *reply)
{
    int i;

    if(!reply)
    {
        fprintf(stderr, "Failed to query tree for window " WINFMT ".\n",
            (unsigned int) wid);
        return 0;
    }

    printf("Window " WINFMT " has parent " WINFMT ", root " WINFMT ", and %d children%c\n",
        (unsigned int) wid,
        (unsigned int) reply->parent,
        (unsigned int) reply->root,
        (unsigned int) reply->nChildren,
        reply->nChildren ? ':' : '.');

    for(i = 0; i < reply->nChildren; ++i)
        printf("    window " WINFMT "\n",
            (unsigned int) XCB_QUERYTREE_CHILDREN(reply)[i]);

    fflush(stdout);
    return 1;
}

static const char *labelError[] = {
    "Success",
    "BadRequest",
    "BadValue",
    "BadWindow",
    "BadPixmap",
    "BadAtom",
    "BadCursor",
    "BadFont",
    "BadMatch",
    "BadDrawable",
    "BadAccess",
    "BadAlloc",
    "BadColor",
    "BadGC",
    "BadIDChoice",
    "BadName",
    "BadLength",
    "BadImplementation",
};

static const char *labelRequest[] = {
    "no request",
    "CreateWindow",
    "ChangeWindowAttributes",
    "GetWindowAttributes",
    "DestroyWindow",
    "DestroySubwindows",
    "ChangeSaveSet",
    "ReparentWindow",
    "MapWindow",
    "MapSubwindows",
    "UnmapWindow",
    "UnmapSubwindows",
    "ConfigureWindow",
    "CirculateWindow",
    "GetGeometry",
    "QueryTree",
    "InternAtom",
    "GetAtomName",
    "ChangeProperty",
    "DeleteProperty",
    "GetProperty",
    "ListProperties",
    "SetSelectionOwner",
    "GetSelectionOwner",
    "ConvertSelection",
    "SendEvent",
    "GrabPointer",
    "UngrabPointer",
    "GrabButton",
    "UngrabButton",
    "ChangeActivePointerGrab",
    "GrabKeyboard",
    "UngrabKeyboard",
    "GrabKey",
    "UngrabKey",
    "AllowEvents",
    "GrabServer",
    "UngrabServer",
    "QueryPointer",
    "GetMotionEvents",
    "TranslateCoords",
    "WarpPointer",
    "SetInputFocus",
    "GetInputFocus",
    "QueryKeymap",
    "OpenFont",
    "CloseFont",
    "QueryFont",
    "QueryTextExtents",
    "ListFonts",
    "ListFontsWithInfo",
    "SetFontPath",
    "GetFontPath",
    "CreatePixmap",
    "FreePixmap",
    "CreateGC",
    "ChangeGC",
    "CopyGC",
    "SetDashes",
    "SetClipRectangles",
    "FreeGC",
    "ClearArea",
    "CopyArea",
    "CopyPlane",
    "PolyPoint",
    "PolyLine",
    "PolySegment",
    "PolyRectangle",
    "PolyArc",
    "FillPoly",
    "PolyFillRectangle",
    "PolyFillArc",
    "PutImage",
    "GetImage",
    "PolyText",
    "PolyText",
    "ImageText",
    "ImageText",
    "CreateColormap",
    "FreeColormap",
    "CopyColormapAndFree",
    "InstallColormap",
    "UninstallColormap",
    "ListInstalledColormaps",
    "AllocColor",
    "AllocNamedColor",
    "AllocColorCells",
    "AllocColorPlanes",
    "FreeColors",
    "StoreColors",
    "StoreNamedColor",
    "QueryColors",
    "LookupColor",
    "CreateCursor",
    "CreateGlyphCursor",
    "FreeCursor",
    "RecolorCursor",
    "QueryBestSize",
    "QueryExtension",
    "ListExtensions",
    "ChangeKeyboardMapping",
    "GetKeyboardMapping",
    "ChangeKeyboardControl",
    "GetKeyboardControl",
    "Bell",
    "ChangePointerControl",
    "GetPointerControl",
    "SetScreenSaver",
    "GetScreenSaver",
    "ChangeHosts",
    "ListHosts",
    "SetAccessControl",
    "SetCloseDownMode",
    "KillClient",
    "RotateProperties",
    "ForceScreenSaver",
    "SetPointerMapping",
    "GetPointerMapping",
    "SetModifierMapping",
    "GetModifierMapping",
    "major 120",
    "major 121",
    "major 122",
    "major 123",
    "major 124",
    "major 125",
    "major 126",
    "NoOperation",
};

static const char *labelEvent[] = {
    "error",
    "reply",
    "KeyPress",
    "KeyRelease",
    "ButtonPress",
    "ButtonRelease",
    "MotionNotify",
    "EnterNotify",
    "LeaveNotify",
    "FocusIn",
    "FocusOut",
    "KeymapNotify",
    "Expose",
    "GraphicsExpose",
    "NoExpose",
    "VisibilityNotify",
    "CreateNotify",
    "DestroyNotify",
    "UnmapNotify",
    "MapNotify",
    "MapRequest",
    "ReparentNotify",
    "ConfigureNotify",
    "ConfigureRequest",
    "GravityNotify",
    "ResizeRequest",
    "CirculateNotify",
    "CirculateRequest",
    "PropertyNotify",
    "SelectionClear",
    "SelectionRequest",
    "SelectionNotify",
    "ColormapNotify",
    "ClientMessage",
    "MappingNotify",
};

static const char *labelSendEvent[] = {
    "",
    " (from SendEvent)",
};

int formatEvent(XCB_Event *e)
{
    BYTE sendEvent;

    if(!e)
    {
        fprintf(stderr, "Error reading event from server.\n");
        return 0;
    }

    sendEvent = (e->type & 0x80) ? 1 : 0;
    e->type &= ~0x80;

    switch(e->type)
    {
    case 0:
        printf("%s on seqnum %d (%s).\n",
            labelError[e->error.errorCode],
            e->error.sequenceNumber,
            labelRequest[e->error.majorCode]);
        break;
    default:
        printf("%s following seqnum %d%s.\n",
            labelEvent[e->event.u.u.type],
            e->event.u.u.sequenceNumber,
            labelSendEvent[sendEvent]);
        break;
    case KeymapNotify:
        printf("%s%s.\n",
            labelEvent[e->keymapEvent.type],
            labelSendEvent[sendEvent]);
        break;
    }

    fflush(stdout);
    return 1;
}
