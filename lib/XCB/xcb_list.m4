XCBGEN(xcb_list, `
Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
All Rights Reserved.  See the file COPYING in this directory
for licensing information.
')
SOURCEONLY(`
REQUIRE(stdlib)
')HEADERONLY(`
STRUCT(XCBListNode, `
    POINTERFIELD(struct XCBListNode, `next')
    POINTERFIELD(void, `data')
')

STRUCT(XCBList, `
    POINTERFIELD(XCBListNode, `head')
    POINTERFIELD(XCBListNode, `tail')
')
')dnl end HEADERONLY

/* Linked list functions */

FUNCTION(`void XCBListInit', `XCBList *list', `
    list->head = list->tail = 0;
')
_C
FUNCTION(`void XCBListInsert', `XCBList *list, void *data', `
    XCBListNode *node;
ALLOC(XCBListNode, `node', 1)
    node->data = data;

    node->next = list->head;
    list->head = node;
    if(!list->tail)
        list->tail = node;
')
_C
FUNCTION(`void XCBListAppend', `XCBList *list, void *data', `
    XCBListNode *node;
ALLOC(XCBListNode, `node', 1)
    node->data = data;
    node->next = 0;

    if(list->tail)
        list->tail->next = node;
    else
        list->head = node;

    list->tail = node;
')
_C
FUNCTION(`void *XCBListRemoveHead', `XCBList *list', `
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
')
_C
FUNCTION(`void *XCBListRemove', `XCBList *list, int (*cmp)(const void *, const void *), const void *data', `
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
')
_C
FUNCTION(`void *XCBListFind', `XCBList *list, int (*cmp)(const void *, const void *), const void *data', `
    XCBListNode *cur = list->head;
    while(cur)
    {
        if(cmp(data, cur->data))
            return cur->data;
        cur = cur->next;
    }
    return 0;
')
_C
FUNCTION(`int XCBListIsEmpty', `XCBList *list', `
    return (list->head == 0);
')
ENDXCBGEN
