#include "xclint.h"
// #include "Xintatom.h"

/* XXX: this implementation does no caching. */

char *XGetAtomName(Display *dpy, Atom atom)
{
    register XCBConnection *c = XCBConnectionOfDisplay(dpy);
    XCBGetAtomNameRep *rep;
    int len;

    rep = XCBGetAtomNameReply(c, XCBGetAtomName(c, XCLATOM(atom)), 0);
    if(!rep)
	return 0;

    len = rep->name_len;
    /* reuse the memory chunk the reply came in. */
    memmove(rep, XCBGetAtomNamename(rep), len);
    ((char *) rep)[len] = '\0';
    return (char *) rep;
}

#if 0 /* not needed yet */
typedef struct {
    unsigned long start_seq;
    unsigned long stop_seq;
    Atom *atoms;
    char **names;
    int idx;
    int count;
    Status status;
} _XGetAtomNameState;

static
Bool _XGetAtomNameHandler(
    register Display *dpy,
    register xReply *rep,
    char *buf,
    int len,
    XPointer data)
{
    register _XGetAtomNameState *state;
    xGetAtomNameReply replbuf;
    register xGetAtomNameReply *repl;

    state = (_XGetAtomNameState *)data;
    if (dpy->last_request_read < state->start_seq ||
	dpy->last_request_read > state->stop_seq)
	return False;
    while (state->idx < state->count && state->names[state->idx])
	state->idx++;
    if (state->idx >= state->count)
	return False;
    if (rep->generic.type == X_Error) {
	state->status = 0;
	return False;
    }
    repl = (xGetAtomNameReply *)
	_XGetAsyncReply(dpy, (char *)&replbuf, rep, buf, len,
			(SIZEOF(xGetAtomNameReply) - SIZEOF(xReply)) >> 2,
			False);
    state->names[state->idx] = (char *) Xmalloc(repl->nameLength+1);
    _XGetAsyncData(dpy, state->names[state->idx], buf, len,
		   SIZEOF(xGetAtomNameReply), repl->nameLength,
		   repl->length << 2);
    if (state->names[state->idx]) {
	state->names[state->idx][repl->nameLength] = '\0';
	_XUpdateAtomCache(dpy, state->names[state->idx],
			  state->atoms[state->idx], 0, -1, 0);
    } else {
	state->status = 0;
    }
    return True;
}

Status XGetAtomNames(Display *dpy, Atom *atoms, int count, char **names_return)
{
    _XAsyncHandler async;
    _XGetAtomNameState async_state;
    xGetAtomNameReply rep;
    int i;
    int missed = -1;

    LockDisplay(dpy);
    async_state.start_seq = dpy->request + 1;
    async_state.atoms = atoms;
    async_state.names = names_return;
    async_state.idx = 0;
    async_state.count = count - 1;
    async_state.status = 1;
    async.next = dpy->async_handlers;
    async.handler = _XGetAtomNameHandler;
    async.data = (XPointer)&async_state;
    dpy->async_handlers = &async;
    for (i = 0; i < count; i++) {
	if (!(names_return[i] = _XGetAtomName(dpy, atoms[i]))) {
	    missed = i;
	    async_state.stop_seq = dpy->request;
	}
    }
    if (missed >= 0) {
	if (_XReply(dpy, (xReply *)&rep, 0, xFalse)) {
	    if ((names_return[missed] = (char *) Xmalloc(rep.nameLength+1))) {
		_XReadPad(dpy, names_return[missed], (long)rep.nameLength);
		names_return[missed][rep.nameLength] = '\0';
		_XUpdateAtomCache(dpy, names_return[missed], atoms[missed],
				  0, -1, 0);
	    } else {
		_XEatData(dpy, (unsigned long) (rep.nameLength + 3) & ~3);
		async_state.status = 0;
	    }
	}
    }
    DeqAsyncHandler(dpy, &async);
    UnlockDisplay(dpy);
    if (missed >= 0)
	SyncHandle();
    return async_state.status;
}
#endif
