/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <assert.h>
#include <xcb_list.h>

#include <stdlib.h>

typedef struct XCBListNode {
    struct XCBListNode *next;
    void *data;
} XCBListNode;

struct XCBList {
    XCBListNode *head;
    XCBListNode *tail;
};

/* Linked list functions */

XCBList *XCBListNew()
{
    XCBList *list;
    list = (XCBList *) malloc(sizeof(XCBList));
    assert(list);
    list->head = list->tail = 0;
    return list;
}

void XCBListInsert(XCBList *list, void *data)
{
    XCBListNode *node;
    node = (XCBListNode *) malloc(sizeof(XCBListNode));
    assert(node);
    node->data = data;

    node->next = list->head;
    list->head = node;
    if(!list->tail)
        list->tail = node;
}

void XCBListAppend(XCBList *list, void *data)
{
    XCBListNode *node;
    node = (XCBListNode *) malloc(sizeof(XCBListNode));
    assert(node);
    node->data = data;
    node->next = 0;

    if(list->tail)
        list->tail->next = node;
    else
        list->head = node;

    list->tail = node;
}

void *XCBListRemoveHead(XCBList *list)
{
    void *ret;
    XCBListNode *tmp = list->head;
    if(!tmp)
        return 0;
    ret = tmp->data;
    list->head = tmp->next;
    if(!list->head)
        list->tail = 0;
    free(tmp);
    return ret;
}

void *XCBListRemove(XCBList *list, int (*cmp)(const void *, const void *), const void *data)
{
    XCBListNode *prev = 0, *cur = list->head;
    void *tmp;

    while(cur)
    {
        if(cmp(data, cur->data))
            break;
        prev = cur;
        cur = cur->next;
    }
    if(!cur)
        return 0;

    if(prev)
        prev->next = cur->next;
    else
        list->head = cur->next;
    if(!cur->next)
        list->tail = prev;

    tmp = cur->data;
    free(cur);
    return tmp;
}

void *XCBListFind(XCBList *list, int (*cmp)(const void *, const void *), const void *data)
{
    XCBListNode *cur = list->head;
    while(cur)
    {
        if(cmp(data, cur->data))
            return cur->data;
        cur = cur->next;
    }
    return 0;
}

int XCBListIsEmpty(XCBList *list)
{
    return (list->head == 0);
}
