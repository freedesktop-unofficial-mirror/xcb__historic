/* Copyright (C) 2001-2004 Bart Massey and Jamey Sharp.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * Except as contained in this notice, the names of the authors or their
 * institutions shall not be used in advertising or otherwise to promote the
 * sale, use or other dealings in this Software without prior written
 * authorization from the authors.
 */

/* A generic implementation of a list of void-pointers. */

#include <stdlib.h>

#include "xcb.h"
#include "xcbint.h"

typedef struct node {
    struct node *next;
    void *data;
} node;

struct _xcb_list {
    node *head;
    node **tail;
    int len;
};

/* Private interface */

_xcb_list *_xcb_list_new()
{
    _xcb_list *list;
    list = malloc(sizeof(_xcb_list));
    if(!list)
        return 0;
    list->head = 0;
    list->tail = &list->head;
    list->len = 0;
    return list;
}

void _xcb_list_clear(_xcb_list *list, XCBListFreeFunc do_free)
{
    void *tmp;
    while((tmp = _xcb_list_remove_head(list)))
        if(do_free)
            do_free(tmp);
}

void _xcb_list_delete(_xcb_list *list, XCBListFreeFunc do_free)
{
    _xcb_list_clear(list, do_free);
    free(list);
}

int _xcb_list_insert(_xcb_list *list, void *data)
{
    node *cur;
    cur = malloc(sizeof(node));
    if(!cur)
        return 0;
    cur->data = data;

    cur->next = list->head;
    list->head = cur;
    ++list->len;
    return 1;
}

int _xcb_list_append(_xcb_list *list, void *data)
{
    node *cur;
    cur = malloc(sizeof(node));
    if(!cur)
        return 0;
    cur->data = data;
    cur->next = 0;

    *list->tail = cur;
    list->tail = &cur->next;
    ++list->len;
    return 1;
}

void *_xcb_list_remove_head(_xcb_list *list)
{
    void *ret;
    node *tmp = list->head;
    if(!tmp)
        return 0;
    ret = tmp->data;
    list->head = tmp->next;
    if(!list->head)
        list->tail = &list->head;
    free(tmp);
    --list->len;
    return ret;
}

void *_xcb_list_remove(_xcb_list *list, int (*cmp)(const void *, const void *), const void *data)
{
    node **cur;
    for(cur = &list->head; *cur; cur = &(*cur)->next)
        if(cmp(data, (*cur)->data))
        {
            node *tmp = *cur;
            void *ret = (*cur)->data;
            *cur = (*cur)->next;
            if(!*cur)
                list->tail = cur;

            free(tmp);
            --list->len;
            return ret;
        }
    return 0;
}

void *_xcb_list_find(_xcb_list *list, int (*cmp)(const void *, const void *), const void *data)
{
    node *cur;
    for(cur = list->head; cur; cur = cur->next)
        if(cmp(data, cur->data))
            return cur->data;
    return 0;
}

int _xcb_list_length(_xcb_list *list)
{
    return list->len;
}
