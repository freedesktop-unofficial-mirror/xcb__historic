
#include <X11/XCB/xcb.h>
#include <X11/XCB/xcb_render.h>
#include <stdio.h>

/*
 * FUNCTION PROTOTYPES
 */
int print_version_info(XCBRenderQueryVersionRep *reply);
int print_formats_info(XCBRenderQueryPictFormatsRep *reply);
int draw_window(XCBConnection *conn, XCBRenderQueryPictFormatsRep *reply);
PICTFORMAT get_pictformat_from_visual(XCBRenderQueryPictFormatsRep *reply, VISUALID visual);
PICTFORMINFO *get_pictforminfo(XCBRenderQueryPictFormatsRep *reply, PICTFORMINFO *query);

XCBConnection   *c;
PICTFORMAT pf;

int print_version_info(XCBRenderQueryVersionRep *reply)
{
    
    fprintf(stdout, "Render Version: %d.%d\n", reply->major_version, 
            reply->minor_version);
}

int print_formats_info(XCBRenderQueryPictFormatsRep *reply)
{
    PICTFORMINFO *first_forminfo;
    int num_formats;
    int num_screens;
    int num_depths;
    int num_visuals;
    PICTFORMINFOIter forminfo_iter;
    PICTSCREENIter     screen_iter;
    
    forminfo_iter = XCBRenderQueryPictFormatsformats(reply);
    screen_iter =  XCBRenderQueryPictFormatsscreens(reply);

    fprintf(stdout, "Number of PictFormInfo iterations: %d\n", forminfo_iter.rem);

    num_formats = reply->num_formats;
    first_forminfo = forminfo_iter.data;
    pf = first_forminfo->id;
    while(forminfo_iter.rem)
    {
        PICTFORMINFO *forminfo = (PICTFORMINFO *)forminfo_iter.data;

        fprintf(stdout, "PICTFORMINFO #%d\n", 1 + num_formats - forminfo_iter.rem);
        fprintf(stdout, "    PICTFORMAT ID:          %d\n", forminfo->id.xid);
        fprintf(stdout, "    PICTFORMAT Type:        %d\n", forminfo->type);
        fprintf(stdout, "    PICTFORMAT Depth:       %d\n", forminfo->depth);
        fprintf(stdout, "        Direct RedShift:    %d\n", forminfo->direct.red_shift);
        fprintf(stdout, "        Direct RedMask:     %d\n", forminfo->direct.red_mask);
        fprintf(stdout, "        Direct BlueShift:   %d\n", forminfo->direct.blue_shift);
        fprintf(stdout, "        Direct BlueMask:    %d\n", forminfo->direct.blue_mask);
        fprintf(stdout, "        Direct GreenShift:  %d\n", forminfo->direct.green_shift);
        fprintf(stdout, "        Direct GreenMask:   %d\n", forminfo->direct.green_mask);
        fprintf(stdout, "        Direct AlphaShift:  %d\n", forminfo->direct.alpha_shift);
        fprintf(stdout, "        Direct AlphaMask:   %d\n", forminfo->direct.alpha_mask);
        fprintf(stdout, "\n");
        PICTFORMINFONext(&forminfo_iter);
    }

    num_screens = reply->num_screens;
    while(screen_iter.rem)
    {
        PICTDEPTHIter depth_iter;
        PICTSCREEN *cscreen = screen_iter.data;
        
        fprintf(stdout, "Screen #%d\n", 1 + num_screens - screen_iter.rem);
        fprintf(stdout, "    Depths for this screen:    %d\n", cscreen->num_depths);
        fprintf(stdout, "    Fallback PICTFORMAT:       %d\n", cscreen->fallback.xid);
        depth_iter = PICTSCREENdepths(cscreen);

        num_depths = cscreen->num_depths;
        while(depth_iter.rem)
        {
            PICTVISUALIter    visual_iter;
            PICTDEPTH *cdepth = depth_iter.data;

            fprintf(stdout, "    Depth #%d\n", 1 + num_depths - depth_iter.rem);
            fprintf(stdout, "        Visuals for this depth:    %d\n", cdepth->num_visuals);
            fprintf(stdout, "        Depth:                     %d\n", cdepth->depth);
            visual_iter = PICTDEPTHvisuals(cdepth);

            num_visuals = cdepth->num_visuals;
            while(visual_iter.rem)
            {
                PICTVISUAL *cvisual = visual_iter.data;
                
                fprintf(stdout, "        Visual #%d\n", 1 + num_visuals - visual_iter.rem);
                fprintf(stdout, "            VISUALID:      %d\n", cvisual->visual.id);
                fprintf(stdout, "            PICTFORMAT:    %d\n", cvisual->format.xid);
                PICTVISUALNext(&visual_iter);
            }
            PICTDEPTHNext(&depth_iter);
        }
        PICTSCREENNext(&screen_iter);
    }
    return 0;
}

int draw_window(XCBConnection *conn, XCBRenderQueryPictFormatsRep *reply)
{
    WINDOW          window;
    DRAWABLE        window_drawable, tmp, root_drawable;
    PIXMAP          surfaces[4], alpha_surface;
    PICTFORMAT      alpha_mask_format, window_format, surface_format;
    PICTURE         window_pict, pict_surfaces[4], alpha_pict, 
                        no_picture = {0}, root_picture;
    PICTFORMINFO    *forminfo_ptr, *alpha_forminfo_ptr, query;
    CARD32          value_mask, value_list[4];
    RECTANGLE       pict_rect[1], window_rect;
    COLOR           pict_color[4], back_color, alpha_color;
    SCREEN          *root;
    int index;

    root = XCBConnSetupSuccessReproots(c->setup).data;
    root_drawable.window = root->root;
   
    /* Setting query so that it will search for an 8 bit alpha surface. */
    query.id.xid = 0;
    query.type = PictTypeDirect;
    query.depth = 8;
    query.direct.red_mask = 0;
    query.direct.green_mask = 0;
    query.direct.blue_mask = 0;
    query.direct.alpha_mask = 255;

    /* Get the PICTFORMAT associated with the window. */
    window_format = get_pictformat_from_visual(reply, root->root_visual);

    /* Get the PICTFORMAT we will use for the alpha mask */
    alpha_forminfo_ptr = get_pictforminfo(reply, &query);
    alpha_mask_format.xid = alpha_forminfo_ptr->id.xid;
    
    /* resetting certain parts of query to search for the surface format */
    query.depth = 24;
    query.direct.alpha_mask = 0;
  
    /* Get the surface forminfo and PICTFORMAT */
    forminfo_ptr = get_pictforminfo(reply, &query);
    surface_format.xid = forminfo_ptr->id.xid;
    
    /* assign XIDs to all of the drawables and pictures */
    for(index = 0; index < 4; index++)
    {
        surfaces[index] = XCBPIXMAPNew(conn);
        pict_surfaces[index] = XCBPICTURENew(conn);
    }
    alpha_surface = XCBPIXMAPNew(conn);
    alpha_pict = XCBPICTURENew(conn);
    window = XCBWINDOWNew(conn);
    window_pict = XCBPICTURENew(conn);
    window_drawable.window = window;
    root_picture = XCBPICTURENew(conn);
    
    /* Here we will create the pixmaps that we will use */
    for(index = 0; index < 4; index++)
    {
        surfaces[index] = XCBPIXMAPNew(conn);
        XCBCreatePixmap(conn, 24, surfaces[index], root_drawable, 200, 200);
    }
    alpha_surface = XCBPIXMAPNew(conn);
    XCBCreatePixmap(conn, 8, alpha_surface, root_drawable, 300, 300);
    
    /* initialize the value list */
    value_mask = XCBCWEventMask;
    value_list[0] = XCBExpose;
    
    /* Create the window */
    XCBCreateWindow(conn, /* XCBConnection */
            0,  /* depth, 0 means it will copy it from the parent */
            window, root_drawable.window, /* window and parent */
            0, 0,   /* x and y */
            300, 300,   /* width and height */
            0,  /* border width */
            InputOutput,    /* class */
            root->root_visual,   /* VISUALID */
            value_mask, value_list); /* LISTofVALUES */
    
    XCBSync(conn, 0);
    
    /* 
     * Create the pictures 
     */
    value_mask = 1<<0; /* repeat (still needs to be added to xcb_render.m4) */
    value_list[0] = 1;

    XCBRenderCreatePicture(conn, root_picture, root_drawable, window_format,
            value_mask, value_list);
    XCBRenderCreatePicture(conn, window_pict, window_drawable, window_format,
            value_mask, value_list);
    tmp.pixmap = alpha_surface;
    XCBRenderCreatePicture(conn, alpha_pict, tmp, alpha_mask_format,
            value_mask, value_list);
    for(index = 0; index < 4; index++)
    {
        tmp.pixmap = surfaces[index];
        XCBRenderCreatePicture(conn, pict_surfaces[index], tmp, surface_format,
                value_mask, value_list);
    }
    XCBSync(conn, 0);

    /* 
     * initialize the rectangles
     */
    window_rect.x = 0;
    window_rect.y = 0;
    window_rect.width = 300;
    window_rect.height = 300;

    pict_rect[0].x = 0;
    pict_rect[0].y = 0;
    pict_rect[0].width = 200;
    pict_rect[0].height = 200;
   
    /* 
     * initialize the colors
     */
    back_color.red = 0x0000;
    back_color.green = 0x0000;
    back_color.blue = 0x0000;
    back_color.alpha = 0x3fff;
   
    pict_color[0].red = 0xffff;
    pict_color[0].green = 0x0000;
    pict_color[0].blue = 0x0000;
    pict_color[0].alpha = 0xffff;
    
    pict_color[1].red = 0x0000;
    pict_color[1].green = 0xffff;
    pict_color[1].blue = 0x0000;
    pict_color[1].alpha = 0xffff;

    pict_color[2].red = 0x0000;
    pict_color[2].green = 0x0000;
    pict_color[2].blue = 0xffff;
    pict_color[2].alpha = 0xffff;

    pict_color[3].red = 0x0000;
    pict_color[3].green = 0x0000;
    pict_color[3].blue = 0xffff;
    pict_color[3].alpha = 0xffff;

    alpha_color.red = 0x0000;
    alpha_color.green = 0x0000;
    alpha_color.blue = 0x0000;
    alpha_color.alpha = 0x4fff;

    /* 
     * Map the window
     */
    XCBSync(conn, 0);
    XCBMapWindow(conn, window);
    XCBSync(conn, 0);
    
    /*
     * Play around with Render
     */

    XCBRenderFillRectangles(conn, PictOpSrc, alpha_pict, alpha_color, 1, pict_rect);
    XCBSync(conn, 0);
    XCBRenderFillRectangles(conn, PictOpSrc, pict_surfaces[0], pict_color[0], 1, pict_rect);
    XCBSync(conn, 0);
    XCBRenderFillRectangles(conn, PictOpSrc, pict_surfaces[1], pict_color[1], 1, pict_rect);
    XCBSync(conn, 0);
    XCBRenderFillRectangles(conn, PictOpSrc, pict_surfaces[2], pict_color[2], 1, pict_rect);
    XCBSync(conn, 0);
    XCBRenderFillRectangles(conn, PictOpSrc, pict_surfaces[3], pict_color[3], 1, pict_rect);
    XCBSync(conn, 0);
    XCBRenderFillRectangles(conn, PictOpOver, window_pict, back_color, 1, &window_rect);
    XCBSync(conn, 0);

    XCBRenderComposite(conn, PictOpOver, root_picture, alpha_pict, window_pict,
            0, 0, 0, 0, 0, 0,
            200, 200);
    XCBSync(conn, 0);
    sleep(1);


    /* Composite the first pict_surface onto the window picture */
    XCBRenderComposite(conn, PictOpOver, pict_surfaces[0], alpha_pict, window_pict,
            0, 0, 0, 0, 100, 100,
            200, 200);
    XCBSync(conn,0);
    sleep(1);
/*
    XCBRenderComposite(conn, PictOpOver, pict_surfaces[0], alpha_pict, window_pict,
            0, 0, 0, 0, 0, 0,
            200, 200);
    XCBSync(conn,0);
    sleep(1);
*/
    XCBRenderComposite(conn, PictOpOver, pict_surfaces[1], alpha_pict, window_pict,
            0, 0, 0, 0, 0, 0,
            200, 200);
    XCBSync(conn,0);
    sleep(1);
    
    XCBRenderComposite(conn, PictOpOver, pict_surfaces[2], alpha_pict, window_pict,
            0, 0, 0, 0, 100, 0,
            200, 200);
    XCBSync(conn,0);
    sleep(1);
    
    XCBRenderComposite(conn, PictOpOver, pict_surfaces[3], alpha_pict, window_pict,
            0, 0, 0, 0, 0, 100,
            200, 200);
    XCBSync(conn,0);
    sleep(1);
    
    XCBRenderComposite(conn, PictOpOver, root_picture, alpha_pict, window_pict,
            0, 0, 0, 0, 0, 0,
            200, 200);
    XCBSync(conn, 0);
    sleep(1);
    
    /* Free up all of the resources we used */
    for(index = 0; index < 4; index++)
    {
        XCBFreePixmap(conn, surfaces[index]);
        XCBRenderFreePicture(conn, pict_surfaces[index]);
    }
    XCBFreePixmap(conn, alpha_surface);
    XCBRenderFreePicture(conn, alpha_pict);
    XCBRenderFreePicture(conn, window_pict);
   
    /* sync up and leave the function */
    XCBSync(conn, 0);
    return 0;
}


/**********************************************************
 * This function searches through the reply for a 
 * PictVisual who's VISUALID is the same as the one
 * specified in query. The function will then return the
 * PICTFORMAT from that PictVIsual structure. 
 * This is useful for getting the PICTFORMAT that is
 * the same visual type as the root window.
 **********************************************************/
PICTFORMAT get_pictformat_from_visual(XCBRenderQueryPictFormatsRep *reply, VISUALID query)
{
    PICTSCREENIter screen_iter;
    PICTSCREEN    *cscreen;
    PICTDEPTHIter  depth_iter;
    PICTDEPTH     *cdepth;
    PICTVISUALIter visual_iter; 
    PICTVISUAL    *cvisual;
    PICTFORMAT  return_value;
    
    screen_iter = XCBRenderQueryPictFormatsscreens(reply);

    while(screen_iter.rem)
    {
        cscreen = screen_iter.data;
        
        depth_iter = PICTSCREENdepths(cscreen);
        while(depth_iter.rem)
        {
            cdepth = depth_iter.data;

            visual_iter = PICTDEPTHvisuals(cdepth);
            while(visual_iter.rem)
            {
                cvisual = visual_iter.data;

                if(cvisual->visual.id == query.id)
                {
                    return cvisual->format;
                }
                PICTVISUALNext(&visual_iter);
            }
            PICTDEPTHNext(&depth_iter);
        }
        PICTSCREENNext(&screen_iter);
    }
    return_value.xid = 0;
    return return_value;
}

PICTFORMINFO *get_pictforminfo(XCBRenderQueryPictFormatsRep *reply, PICTFORMINFO *query)
{
    PICTFORMINFOIter forminfo_iter;
    
    forminfo_iter = XCBRenderQueryPictFormatsformats(reply);

    while(forminfo_iter.rem)
    {
        PICTFORMINFO *cformat;
        cformat  = forminfo_iter.data;
        PICTFORMINFONext(&forminfo_iter);

        if( (query->id.xid != 0) && (query->id.xid != cformat->id.xid) )
        {
            continue;
        }

        if(query->type != cformat->type)
        {
            continue;
        }
        
        if( (query->depth != 0) && (query->depth != cformat->depth) )
        {
            continue;
        }
        
        if( (query->direct.red_mask  != 0)&& (query->direct.red_mask != cformat->direct.red_mask))
        {
            continue;
        }
        
        if( (query->direct.green_mask != 0) && (query->direct.green_mask != cformat->direct.green_mask))
        {
            continue;
        }
        
        if( (query->direct.blue_mask != 0) && (query->direct.blue_mask != cformat->direct.blue_mask))
        {
            continue;
        }
        
        if( (query->direct.alpha_mask != 0) && (query->direct.alpha_mask != cformat->direct.alpha_mask))
        {
            continue;
        }
        
        /* This point will only be reached if the pict format   *
         * matches what the user specified                      */
        return cformat; 
    }
    
    return NULL;
}

int main(int argc, char *argv[])
{
    XCBRenderQueryVersionCookie version_cookie;
    XCBRenderQueryVersionRep    *version_reply;
    XCBRenderQueryPictFormatsCookie formats_cookie;
    XCBRenderQueryPictFormatsRep *formats_reply;
    PICTFORMAT  rootformat;
    SCREEN *root;
    
    PICTFORMINFO  forminfo_query, *forminfo_result;
    
    c = XCBConnectBasic();
    root = XCBConnSetupSuccessReproots(c->setup).data;
    
    version_cookie = XCBRenderQueryVersion(c, (CARD32)0, (CARD32)3);
    version_reply = XCBRenderQueryVersionReply(c, version_cookie, 0);

    print_version_info(version_reply);
    
    formats_cookie = XCBRenderQueryPictFormats(c);
    formats_reply = XCBRenderQueryPictFormatsReply(c, formats_cookie, 0);

    draw_window(c, formats_reply);
    
    print_formats_info(formats_reply);
   
    forminfo_query.id.xid = 0;
    forminfo_query.type = PictTypeDirect;
    forminfo_query.depth = 8;
    forminfo_query.direct.red_mask = 0;
    forminfo_query.direct.green_mask = 0;
    forminfo_query.direct.blue_mask = 0;
    forminfo_query.direct.alpha_mask = 255;
    
    forminfo_result = get_pictforminfo(formats_reply, &forminfo_query);
    fprintf(stdout, "\n***** found PICTFORMAT:  %d *****\n",
            forminfo_result->id.xid);
    rootformat = get_pictformat_from_visual(formats_reply, root->root_visual);
    fprintf(stdout, "\n***** found root PICTFORMAT:   %d *****\n", rootformat.xid);
   
    //draw_window(c, formats_reply);
    
    /* It's very important to free the replys. We don't want memory leaks. */
    free(version_reply);
    free(formats_reply);

    exit(0);
}
