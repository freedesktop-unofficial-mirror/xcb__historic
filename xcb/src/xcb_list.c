/*
 * Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
 * All Rights Reserved.  See the file COPYING in this directory
 * for licensing information.
 */

#include <assert.h>
#include "xcb.h"
#include "xcbint.h"

typedef struct XCBListNode {
    struct XCBListNode *next;
    void *data;
} XCBListNode;

struct XCBList {
    XCBListNode *head;
    XCBListNode **tail;
    int len;
};

/* Linked list functions */

XCBList *XCBListNew()
{
    XCBList *list;
    list = (XCBList *) malloc(sizeof(XCBList));
    assert(list);
    list->head = 0;
    list->tail = &list->head;
    list->len = 0;
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
    ++list->len;
}

void XCBListAppend(XCBList *list, void *data)
{
    XCBListNode *node;
    node = (XCBListNode *) malloc(sizeof(XCBListNode));
    assert(node);
    node->data = data;
    node->next = 0;

    *list->tail = node;
    list->tail = &node->next;
    ++list->len;
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
        list->tail = &list->head;
    free(tmp);
    --list->len;
    return ret;
}

void *XCBListRemove(XCBList *list, int (*cmp)(const void *, const void *), const void *data)
{
    XCBListNode **cur;
    for(cur = &list->head; *cur; cur = &(*cur)->next)
        if(cmp(data, (*cur)->data))
	{
	    XCBListNode *tmp = *cur;
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

void *XCBListFind(XCBList *list, int (*cmp)(const void *, const void *), const void *data)
{
    XCBListNode *cur;
    for(cur = list->head; cur; cur = cur->next)
        if(cmp(data, cur->data))
            return cur->data;
    return 0;
}

int XCBListLength(XCBList *list)
{
    return list->len;
}

int XCBListIsEmpty(XCBList *list)
{
    return (list->head == 0);
}
