dnl Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
dnl All Rights Reserved.  See the file COPYING in this directory
dnl for licensing information.
dnl
dnl macros-xcb.m4: Macros specific to the XCB client library
divert(-1) dnl Discard any text until a divert(0).

dnl -- Diversions used internally

dnl List of parameters in a REQUEST
define(`PARMDIV', ALLOCDIV)
dnl Structure assignment code for binding out->* in REQUEST
define(`ASSNDIV', ALLOCDIV)
dnl Variable-length list construction code in REQUEST
define(`LISTDIV', ALLOCDIV)
dnl Variable declarations for REQUEST bodies
define(`VARDIV', ALLOCDIV)
dnl List of values to check to ensure marshaling is OK in REQUEST
define(`MARSHALDIV', ALLOCDIV)
dnl Holds body of structure declared with STRUCT or UNION macros
define(`STRUCTDIV', ALLOCDIV)
dnl Buffers all structures until end of input
define(`TYPEDIV', ALLOCDIV)

dnl PAD, FIELD, ARRAYFIELD, and POINTERFIELD can be used in either STRUCT or
dnl UNION definitions.
define(`FIELDQTY', 0)
define(`PADQTY', 0)



dnl -- Counters for various internal values

dnl Variable length elements in request
define(`PARTQTY', 0)
dnl Parameters to request (currently tests only for zero/nonzero)
define(`PARAMQTY', 0)


dnl -- Request/Response macros

dnl The *PARAM and *FIELD macros must only appear inside a REQUEST or
dnl VOIDREQUEST macro call, and must be quoted. All fields must appear
dnl in the order the X server expects to recieve them in. Parameters to
dnl the generated request functions will appear in the same order as the
dnl PARAM/FIELD macros they're related to.


dnl The X protocol specification says that the X name of the extension
dnl "should use the ISO Latin-1 encoding, and uppercase and lowercase matter."
dnl The C name should be a valid C identifier which can be guessed easily
dnl from the X name, as it will appear in programmer-visible names.
dnl BEGINEXTENSION(X name, C name)
define(`BEGINEXTENSION', `define(`EXTENSION', `XCB`'$2`'Id')dnl
_H`'REQUIRE(X11, XCB, xcb)

_H`'extern const char EXTENSION[];
_C`'const char EXTENSION[] = "`$1'";
FUNCTION(`const XCBQueryExtensionRep *XCB`'$2`'Init', `XCBConnection *c', `
    return XCBQueryExtensionCached(c, EXTENSION, 0);
')')

dnl ENDEXTENSION()
define(`ENDEXTENSION', `undefine(`EXTENSION')dnl')


dnl Defines an enumerated protocol type.
dnl XCBENUM(type name, name list)
define(`XCBENUM', `ENUM(XCB`$1', shift($@))')


dnl Defines a BITMASK/LISTofVALUE parameter pair. The bitmask type should
dnl probably be either CARD16 or CARD32, depending on the specified width
dnl of the bitmask. The value array must be given to the generated
dnl function in the order the X server expects.
dnl VALUEPARAM(bitmask type, bitmask name, value array name)
define(`VALUEPARAM', `
PARAM(`$1', `$2')
LISTPARAM(CARD32, `$3', `XCBOnes($2)')
')

dnl Defines a LISTofFOO parameter. The length of the list may be given as
dnl any C expression and may reference any of the other fields of this
dnl request.
dnl LISTPARAM(element type, list name, length expression)
define(`LISTPARAM', `PUSHDIV(PARMDIV), const `$1' *`$2'divert(LISTDIV)
TAB()parts[PARTQTY].iov_base = (caddr_t) `$2';
TAB()parts[PARTQTY].iov_len = (`$3') * sizeof(`$1');
TAB()out->length += (parts[PARTQTY].iov_len + 3) >> 2;
POPDIV()define(`PARTQTY', eval(1+PARTQTY))')

dnl Defines a field which should be filled in with the given expression.
dnl The field name is available for use in the expression of a LISTPARAM
dnl or a following EXPRFIELD.
dnl EXPRFIELD(field type, field name, expression)
define(`EXPRFIELD', `FIELD(`$1', `$2')
PUSHDIV(VARDIV)dnl
TAB()$1 `$2' = `$3';
divert(ASSNDIV)ifdef(`MARSHALABLE', `INDENT()')dnl
TAB()out->`$2' = `$2';
ifdef(`MARSHALABLE', `UNINDENT()')POPDIV()ifelse(FIELDQTY, 2, `LENGTHFIELD()')')

dnl Defines a parameter with no associated field. The name can be used in
dnl expressions.
dnl LOCALPARAM(type, name)
define(`LOCALPARAM', `PUSHDIV(PARMDIV), $1 `$2'POPDIV()')

dnl Defines a parameter with a field of the same type.
dnl PARAM(type, name)
define(`PARAM', `FIELD($1, `$2')
PUSHDIV(PARMDIV), $1 `$2'`'dnl
divert(ASSNDIV)ifdef(`MARSHALABLE', `INDENT()')dnl
TAB()out->`$2' = `$2';
ifdef(`MARSHALABLE', `UNINDENT()')POPDIV()define(`PARAMQTY', eval(1+PARAMQTY))
ifelse(FIELDQTY, 2, `LENGTHFIELD()')')

dnl Sets the major number for all instances of this request to the given code.
dnl OPCODE(number)
define(`OPCODE', `ifdef(`EXTENSION', `
    FIELD(CARD8, `major_opcode')
    FIELD(CARD8, `minor_opcode')
PUSHDIV(VARDIV)dnl
TAB()const XCBQueryExtensionRep *extension = XCBQueryExtensionCached(c, EXTENSION, 0);
TAB()const CARD8 major_opcode = extension->major_opcode;
TAB()const CARD8 minor_opcode = `$1';
divert(ASSNDIV)dnl
dnl TODO: better error handling here, please!
TAB()assert(extension && extension->present);

TAB()out->major_opcode = major_opcode;
TAB()out->minor_opcode = minor_opcode;
POPDIV()
    ifelse(FIELDQTY, 2, `LENGTHFIELD()')
', `
    FIELD(CARD8, `major_opcode')
PUSHDIV(VARDIV)dnl
TAB()const CARD8 major_opcode = `$1';
divert(ASSNDIV)ifdef(`MARSHALABLE', `INDENT()')dnl
TAB()out->major_opcode = major_opcode;
ifdef(`MARSHALABLE', `UNINDENT()')POPDIV()
')')


dnl Form of a request function with marshaling:
dnl if !last || last->major_opcode != major_opcode
dnl    do not marshal
dnl if defined(EXTENSION) && last->minor_opcode != minor_opcode
dnl    do not marshal
dnl foreach i in $@: if last->i != i
dnl    do not marshal
dnl if !marshaling
dnl    out = alloc out buffer
dnl    set all fields in out
dnl else
dnl    out = last
dnl set up parts array, update out->length
dnl write parts
dnl MARSHAL(param name ...)
define(`MARSHAL', `
define(`MARSHALABLE')
ifelse($1, , , `
    PUSHDIV(MARSHALDIV) || out->`$1' != `$1'POPDIV()
    MARSHAL(shift($@))
')
')


dnl REPLY(type, name)
define(`REPLY', `FIELD(`$1', `$2')
ifelse(FIELDQTY, 2, `LENGTHFIELD()')')

dnl Generates a C pre-processor macro providing access to a variable-length
dnl portion of a structure. The length parameter is an expression, usually
dnl involving the fixed-length portion of the structure, which evaluates
dnl at run-time to the number of elements in this array.
dnl ARRAYFIELD(field type, field name, list length expr)
define(`ARRAYFIELD', `
INLINEFUNCTION(`$1 *'REQ`$2', REQ`'KIND` *R', `
    return (`$1' *) (NEXTFIELD);
')

INLINEFUNCTION(`int 'REQ`$2'Length, REQ`'KIND` *R', `
    return `$3';
')

define(`NEXTFIELD', REQ`$2'`(R) + (`$3')')')

define(`ARRAYREPLY', `ARRAYFIELD($@)')

dnl Generates an iterator for the variable-length portion of a structure.
dnl LISTFIELD(field type, field name, list length expr)
define(`LISTFIELD', `
FUNCTION(`$1Iter 'REQ`$2', REQ`'KIND` *R', `
TAB()$1Iter i;
TAB()i.data = (`$1' *) (NEXTFIELD);
TAB()i.rem = (`$3');
TAB()return i;
')

define(`NEXTFIELD', `$1AfterIter(REQ`$2'((REQ`'KIND *) R))')')


dnl Creates a function named XCB<name> returning XCBVoidCookie and
dnl accepting whatever parameters are necessary to deliver the given PARAMs
dnl and FIELDs to the X server.
dnl VOIDREQUEST(name, 0 or more PARAMs/FIELDs)
define(`VOIDREQUEST', `REQUESTFUNCTION(`Void', `$1', `$2')')

dnl Creates a function named XCB<name> returning XCB<name>Cookie and
dnl accepting whatever parameters are necessary to deliver the given PARAMs
dnl and FIELDs to the X server. Declares the struct XCB<name>Cookie.
dnl Creates a function named XCB<name>Reply returning a pointer to
dnl XCB<name>Rep which forces a cookie returned from XCB<name>, waiting
dnl for the response from the server if necessary. Declares the struct
dnl XCB<name>Rep. The three parameters must be quoted.
dnl REQUEST(name, 0 or more PARAMs, 0 or more REPLYs)
define(`REQUEST',`REQUESTFUNCTION(`$1', `$1', `$2')
_H
pushdef(`NEXTFIELD', `R + 1')dnl
PACKETSTRUCT(`$1', `Rep', `$3')
INLINEFUNCTION(`XCB'$1`Rep *XCB'$1`Reply',
`XCBConnection *c, XCB'$1`Cookie cookie, XCBGenericEvent **e', `
    XCBREPTRACER("$1");
    return (XCB`'$1`'Rep *) XCBWaitSeqnum(c, cookie.seqnum, e);
')popdef(`NEXTFIELD')')


dnl Internal function shared by REQUEST and VOIDREQUEST, implementing the
dnl common portions of those macros.
dnl REQUESTFUNCTION(return type, request name, parameters)
define(`REQUESTFUNCTION',`dnl
ifelse($1, Void, `dnl', `COOKIETYPE($1)
_H')
pushdef(`PARTQTY', 0)pushdef(`PARAMQTY', 0)dnl
PACKETSTRUCT(`$2', `Req', `$3')
FUNCTION(`XCB'$1`Cookie XCB'$2, `XCBConnection *c`'undivert(PARMDIV)', `
    XCB`$1'Cookie ret;
    XCB`$2'Req *out;
undivert(VARDIV)`'dnl
ifelse(PARTQTY, 0, `dnl', `    struct iovec parts[PARTQTY];')

    pthread_mutex_lock(&c->locked);
ifdef(`MARSHALABLE', `dnl
    out = (XCB`$2'Req *) c->last_request;
    if(!out || out->major_opcode != major_opcode`'dnl
ifdef(`EXTENSION', ` || out->minor_opcode != minor_opcode')`'dnl
undivert(MARSHALDIV))
    {INDENT()
')dnl
TAB()out = (XCB`$2'Req *) XCBAllocOut(c->handle, XCB_CEIL(sizeof(*out)));
TAB()c->last_request = out;
TAB()XCBREQTRACER("$2");

undivert(ASSNDIV)`'dnl

TAB()ret.seqnum = ++c->seqnum;
ifelse($1, Void, `dnl', `    XCBAddReplyData(c, ret.seqnum);')
ifdef(`MARSHALABLE', `dnl
    }UNINDENT()
    else
    {
        XCBMARSHALTRACER("$2");
dnl XXX: it seems bad to return the same seqnum, but I see no other choice.
        ret.seqnum = c->seqnum;
    }
')dnl
undivert(LISTDIV)`'dnl
ifelse(PARTQTY, 0, `dnl', `    XCBWrite(c->handle, parts, PARTQTY);')
    pthread_mutex_unlock(&c->locked);

    return ret;
')popdef(`PARAMQTY')popdef(`PARTQTY')undefine(`MARSHALABLE')')


dnl Declares a struct holding an XID, and a function to allocate new
dnl instances of this struct.
dnl XIDTYPE(name)
define(`XIDTYPE', `STRUCT(`$1', `FIELD(`CARD32', `xid')')
FUNCTION(`$1 XCB'$1`New', `struct XCBConnection *c', `
    `$1' ret = { XCBGenerateID(c) };
    return ret;
')')


dnl Declares a struct named XCB<name>Cookie with a single "int seqnum"
dnl field.
dnl COOKIETYPE(name)
define(`COOKIETYPE', `dnl
TYPEDEF(`struct XCB`$1'Cookie {
    int seqnum;
}', `XCB`$1'Cookie')')


dnl EVENT(name, number, 1 or more FIELDs)
define(`EVENT', `dnl
_H`'#define XCB`$1' `$2'
PACKETSTRUCT(`$1', `Event', `$3')')

dnl EVENTCOPY(new name, new number, old name)
define(`EVENTCOPY', `HEADERONLY(CPPDEFINE(`XCB'`$1', `$2')
)TYPEDEF(`XCB`$3'Event', `XCB`$1'Event')')

dnl ERROR(name, number, 1 or more FIELDs)
define(`ERROR', `dnl
_H`'#define XCB`$1' `$2'
PACKETSTRUCT(`$1', `Error', `$3')')

dnl ERRORCOPY(new name, new number, old name)
define(`ERRORCOPY', `HEADERONLY(CPPDEFINE(`XCB'`$1', `$2')
)TYPEDEF(`XCB`$3'Error', `XCB`$1'Error')')


dnl EVENTMIDDLE()
define(`EVENTMIDDLE', `FIELD(CARD16, `seqnum')')

dnl ERRORMIDDLE()
define(`ERRORMIDDLE', `FIELD(CARD16, `seqnum')')

dnl REPMIDDLE()
define(`REPMIDDLE', `
    FIELD(CARD16, `seqnum')
    FIELD(CARD32, `length')
')

dnl REQMIDDLE()
define(`REQMIDDLE', `FIELD(CARD16, `length')
PUSHDIV(ASSNDIV)ifdef(`MARSHALABLE', `INDENT()')dnl
TAB()out->length = XCB_CEIL(sizeof(*out)) >> 2;
ifdef(`MARSHALABLE', `UNINDENT()')POPDIV()')

dnl STRUCT(name, 1 or more FIELDs)
define(`STRUCT', `PUSHDIV(-1)
define(`NEXTFIELD', `R + 1')
define(`REQ', $1)
define(`KIND')
$2
divert(TYPEDIV)HEADERONLY(`dnl
typedef struct `$1' {
undivert(STRUCTDIV)dnl
} `$1';

typedef struct `$1'Iter {INDENT()
TAB()`$1' *data;
TAB()int rem;
UNINDENT()} `$1'Iter;

')divert(-1)

INLINEFUNCTION(`void `$1'Next', ``$1'Iter *i', `
TAB()$1 *R = i->data;
TAB()--i->rem;
TAB()i->data = ($1 *) (NEXTFIELD());
')

FUNCTION(`void *`$1'AfterIter', ``$1'Iter i', `
TAB()while(i.rem > 0)INDENT()
TAB()`$1'Next(&i);UNINDENT()
TAB()return (void *) i.data;
')

popdef(`LENGTHFIELD')popdef(`REQ')popdef(`KIND')
define(`FIELDQTY', 0)define(`PADQTY', 0)
POPDIV()')

dnl for kind in (Event, Error, Rep, Req)
dnl PACKETSTRUCT(name, kind, 1 or more FIELDs)
define(`PACKETSTRUCT', `PUSHDIV(-1)
pushdef(`REQ', `XCB$1')
pushdef(`KIND', `$2')
pushdef(`LENGTHFIELD', `TOUPPER($2)MIDDLE')
define(`NEXTFIELD', `R + 1')
INDENT()dnl
dnl Everything except requests has a response type.
ifelse(`$2', `Req', , `REPLY(BYTE, `response_type')')
dnl Only errors have an error code.
ifelse(`$2', `Error', `REPLY(BYTE, `error_code')')
$3
dnl Requests and replies always have length fields.
ifelse(FIELDQTY, 1,
    `ifelse(`$2', `Req', `PAD(1)',
    `ifelse(`$2', `Rep', `PAD(1)')')')
UNINDENT()

divert(TYPEDIV)HEADERONLY(`dnl
typedef struct XCB`$1'`$2' {
undivert(STRUCTDIV)dnl
} XCB`$1'`$2';

')divert(-1)

popdef(`LENGTHFIELD')popdef(`REQ')popdef(`KIND')
define(`FIELDQTY', 0)define(`PADQTY', 0)
POPDIV()_H')


dnl -- Other macros

define(`PACKAGE', `X11, XCB')

dnl Generates the standard prefix in the output code. The source file name
dnl should not include extension or path.
dnl XCBGEN(source file name, copyright notice)
define(`XCBGEN', `dnl
`/*'
 * This file generated automatically from $1.m4 by macros-xcb.m4 using m4.
 * Edit at your peril.
` */'

HEADERONLY(`dnl
#ifndef __`'TOUPPER($1)_H
#define __`'TOUPPER($1)_H
REQUIRE(X11, XCB, xcb_trace)
')SOURCEONLY(`dnl
REQUIRE(assert)
REQUIRE(X11, XCB, $1)')')

dnl Generates the standard suffix in the output code.
dnl ENDXCBGEN()
define(`ENDXCBGEN', `dnl
undivert(TYPEDIV)dnl
undivert(FUNCDIV)dnl
undivert(INLINEFUNCDIV)dnl
_H`'#endif')

divert(0)`'dnl
