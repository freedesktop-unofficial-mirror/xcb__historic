/* Copyright (C) 2001-2003 Bart Massey and Jamey Sharp.
 * See the file COPYING for licensing information. */

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
