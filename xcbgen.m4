dnl
dnl generate XCB C code
dnl Bart & Jamey 9/2001
dnl
dnl
dnl Don't insert this text in the source file.
dnl This makes succeeding dnl commands unnecessary but harmless.
dnl
divert(-1)


dnl -- General definitions


dnl GNU m4 m4wrap() executes argument at end of input.
dnl In this case the argument discards unprocessed diversions.
m4wrap(`divert(-1)undivert')

dnl Use C-style comments.
changecom(`/*', `*/')


dnl Push diversion on the diversion stack
dnl PUSHDIV(diversion)
define(`PUSHDIV', `pushdef(`DIVNUM',divnum)divert($1)')

dnl Pop diversion off the diversion stack and discards it
dnl POPDIV()
define(`POPDIV', `divert(DIVNUM)popdef(`DIVNUM')')


dnl Indent current line appropriately by inserting spaces.
dnl TAB()
define(`TAB', `')

dnl Move line indentation to the right 4 spaces.
dnl INDENT()
define(`INDENT', `pushdef(`TAB', `    'TAB)')

dnl Move line indentation to the left 4 spaces.
dnl UNINDENT()
define(`UNINDENT', `popdef(`TAB')')


dnl Transliterates lowercase characters to uppercase.
dnl TOUPPER(string)
define(`TOUPPER', `translit($1, `a-z', `A-Z')')


dnl Exactly one of _H and _C should be set on the command line.
dnl When _H is set, _C lines will be thrown away.
dnl Similarly, when _C is set, _H lines will be thrown away.
dnl Stuff that belongs in header files only should be
dnl prefixed with _H, stuff that belongs in .c files only should
dnl be prefixed with _C.
dnl Note that the define()s are in the else part of the ifdef.
dnl Do not make the obvious change without careful thought.
ifdef(`_H', , `define(`_H', `dnl')')
ifdef(`_C', , `define(`_C', `dnl')')


dnl Declare a C function
dnl Note that this macro also sticks a declaration
dnl in the header file.
dnl FUNCTION(return type and function name, params, body)
define(`FUNCTION', `dnl
$1`('$2`)'_H;
_C
_H`'PUSHDIV(-1)
{INDENT()dnl
'$3`dnl
}UNINDENT()
_H`'POPDIV()dnl')

dnl STATICFUNCTION(return type and function name, params, body)
define(`STATICFUNCTION', `dnl
_C`'static $1`('$2`)'
_H`'PUSHDIV(-1)
{INDENT()dnl
'$3`dnl
}UNINDENT()
_H`'POPDIV()dnl')


dnl Allocate a block or array of storage with a given name.
dnl There is no FREE() macro: just call free().
dnl ALLOC(type, result name, count)
define(`ALLOC', `dnl
TAB()$2 = ($1 *) malloc(($3) * sizeof($1));
TAB()assert($2);')

dnl REALLOC(type, result name, count)
define(`REALLOC', `dnl
TAB()$2 = ($1 *) realloc($2, ($3) * sizeof($1));
TAB()assert($2);')


dnl -- Names used internally

dnl Diversions holding various portions of the generated code.
define(`PARMDIV',   1)  dnl List of parameters in a REQUEST
define(`OUTDIV',    2)  dnl Structure assignment code for
                        dnl binding out->* in REQUEST
define(`VARDIV',    3)  dnl Variable declarations for REQUEST bodies
define(`STRUCTDIV', 4)  dnl Body of structure declared
                        dnl with STRUCT or UNION macros

dnl 
define(`FIELDQTY', 0)  dnl Count of fields in a struct (or request)
define(`PADQTY',   0)  dnl Count of padding fields in a request or reply
define(`PARTQTY',  0)  dnl Count of variable length elements in request
define(`PARAMQTY', 0)  dnl Count of parameters to request (currently tests
                       dnl only for zero/nonzero)


dnl -- Request/Response macros

dnl The *PARAM and *FIELD macros must always appear inside a REQUEST or
dnl VOIDREQUEST macro call, and must be quoted.

dnl VALUEPARAM and LISTPARAM fields must appear in the order the X server
dnl expects to recieve them in; other parameter and field definitions
dnl may be interspersed anywhere and in any order, but it's suggested for
dnl reasons of clarity that these all be listed in the same order as
dnl they're given in the X Protocol specification. Parameters to the
dnl generated request functions will appear in the same order as the
dnl PARAM macros they're related to.



dnl Defines a BITMASK/LISTofVALUE parameter pair. The bitmask type should
dnl probably be either CARD16 or CARD32, depending on the specified width
dnl of the bitmask. The value array must be given to the generated
dnl function in the order the X server expects.
dnl VALUEPARAM(bitmask type, bitmask name, value array name)
define(`VALUEPARAM', `FIELD($1, `$2')`'dnl
PUSHDIV(OUTDIV)
TAB()out->`$2' = `$2';
TAB()out->length += XCB_Ones(`$2');
TAB()parts[PARTQTY].iov_base = `$3';
TAB()parts[PARTQTY].iov_len = XCB_Ones(`$2') * 4;
define(`PARTQTY', eval(1+PARTQTY))dnl
divert(PARMDIV), $1 `$2', CARD32 *`$3'dnl
ifelse(FIELDQTY, 2, `LENGTHFIELD()')dnl
POPDIV()')

dnl Defines a LISTofFOO parameter. The length of the list may be given as
dnl any C expression and may reference any of the other fields of this
dnl request.
dnl LISTPARAM(element type, list name, length expression)
define(`LISTPARAM', `PUSHDIV(PARMDIV), $1 *`$2'dnl
divert(OUTDIV)
TAB()out->length += (`$3') * sizeof($1) / 4;
TAB()parts[PARTQTY].iov_base = `$2';
TAB()parts[PARTQTY].iov_len = (`$3') * sizeof($1);
define(`PARTQTY', eval(1+PARTQTY))dnl
POPDIV()')

dnl Defines a field which should be filled in with the given expression.
dnl The field name is available for use in the expression of a LISTPARAM
dnl or a following EXPRFIELD.
dnl EXPRFIELD(field type, field name, expression)
define(`EXPRFIELD', `FIELD($1, `$2')`'dnl
PUSHDIV(VARDIV)dnl
TAB()$1 `$2' = `$3';
divert(OUTDIV)dnl
TAB()out->`$2' = `$2';
ifelse(FIELDQTY, 2, `LENGTHFIELD()')dnl
POPDIV()')

dnl Defines a parameter with no associated field. The name can be used in
dnl expressions.
dnl LOCALPARAM(type, name)
define(`LOCALPARAM', `PUSHDIV(PARMDIV), $1 `$2'POPDIV()')

dnl Defines a parameter with a field of the same type.
dnl PARAM(type, name)
define(`PARAM', `FIELD($1, `$2')`'dnl
PUSHDIV(PARMDIV), $1 `$2'`'dnl
divert(OUTDIV)dnl
TAB()out->`$2' = `$2';
define(`PARAMQTY', eval(1+PARAMQTY))dnl
ifelse(FIELDQTY, 2, `LENGTHFIELD()')dnl
POPDIV()')

dnl Sets the major number for all instances of this request to the given code.
dnl TODO: for extensions, set the major number to the extension major number,
dnl       and the minor number to this given number.
dnl OPCODE(number)
define(`OPCODE', `FIELD(CARD8, `majorOpcode')`'dnl
PUSHDIV(OUTDIV)dnl
TAB()out->majorOpcode = `$1';
ifelse(FIELDQTY, 2, `LENGTHFIELD()')dnl
POPDIV()')

dnl PAD(bytes)
define(`PAD', `ARRAYFIELD(CARD8, `pad'PADQTY, $1)`'dnl
define(`PADQTY', eval(1+PADQTY))dnl
ifelse(FIELDQTY, 2, `LENGTHFIELD()')')

dnl LENGTHFIELD()
define(`LENGTHFIELD', `FIELD(CARD16, `length')`'dnl
PUSHDIV(OUTDIV)dnl
TAB()out->length = (sizeof(*out) + XCB_PAD(sizeof(*out))) / 4;
POPDIV()')

dnl REPLY(type, name)
define(`REPLY', `FIELD($1, `$2')`'dnl
ifelse(FIELDQTY, 2, `LENGTHREPLY()')')

dnl Generates a C pre-processor macro providing access to a variable-length
dnl portion of a reply. If another reply field follows, the length name
dnl must be provided. The length name is the name of a field in the
dnl fixed-length portion of the response which contains the number of
dnl elements in this section.
dnl ARRAYREPLY(field type, field name, opt length name)
define(`ARRAYREPLY', `PUSHDIV(OUTDIV)dnl
_H`'#define `XCB_'REQ`_'TOUPPER($2)`(reply) (($1 *) ('ifdef(`LASTFIELD', `XCB_'REQ`_'LASTFIELD`(reply) + reply->'LASTLEN, `reply + 1')`))'
POPDIV()define(`LASTFIELD', TOUPPER($2))ifelse($#, 3, `define(`LASTLEN', $3)')')

dnl Generates an iterator for the variable-length portion of a reply.
dnl TODO: um, write this.
dnl LISTREPLY(???)
define(`LISTREPLY', `')

dnl LENGTHREPLY()
define(`LENGTHREPLY', `
    FIELD(CARD16, `seqnum')
    FIELD(CARD32, `length')
')



dnl Creates a function named XCB_<name> returning XCB_void_cookie and
dnl accepting whatever parameters are necessary to deliver the given PARAMs
dnl and FIELDs to the X server.
dnl VOIDREQUEST(name, 0 or more PARAMs/FIELDs)
define(`VOIDREQUEST', `REQUESTFUNCTION(void, $1, `$2')')

dnl Creates a function named XCB_<name> returning XCB_<name>_cookie and
dnl accepting whatever parameters are necessary to deliver the given PARAMs
dnl and FIELDs to the X server. Declares the struct XCB_<name>_cookie.
dnl Creates a function named XCB_<name>_Reply returning a pointer to
dnl XCB_<name>_Rep which forces a cookie returned from XCB_<name>, waiting
dnl for the response from the server if necessary. Declares the struct
dnl XCB_<name>_Rep. The three parameters must be quoted.
dnl REQUEST(name, 0 or more PARAMs, 0 or more REPLYs)
define(`REQUEST',`REQUESTFUNCTION($1, $1, `$2')

INDENT()dnl
pushdef(`REQ', TOUPPER($1))dnl
pushdef(`LENGTHFIELD', defn(`LENGTHREPLY'))dnl So that PAD works right
STRUCT(XCB_`$1'_Rep, `
    FIELD(BYTE, `response_type') dnl always 1 -> reply
    $3
    ifelse(FIELDQTY, 1, `PAD(1)') dnl ensure a length field is included
')
define(`PADQTY', 0)dnl
popdef(`LENGTHFIELD')dnl
popdef(`REQ')dnl
UNINDENT()dnl
undivert(OUTDIV)`'dnl
_H
FUNCTION(`XCB_'$1`_Rep *XCB_'$1`_Reply',
`XCB_Connection *c, XCB_'$1`_cookie cookie, xError **e', `
    return (XCB_'$1`_Rep *) XCB_Wait_Seqnum(c, cookie.seqnum, e);
')`'dnl
undefine(`LASTFIELD')undefine(`LASTLEN')dnl')


dnl Internal function shared by REQUEST and VOIDREQUEST, implementing the
dnl common portions of those macros.
dnl REQUESTFUNCTION(return type, request name, parameters)
define(`REQUESTFUNCTION',`dnl
ifelse($1, void, `dnl', `COOKIETYPE($1)')
INDENT()dnl
STATICSTRUCT(XCB_`$2'_Req, `
    $3
    ifelse(FIELDQTY, 1, `PAD(1)') dnl ensure a length field is included
')
define(`PADQTY', 0)dnl
UNINDENT()dnl
_C
FUNCTION(`XCB_'$1`_cookie XCB_'$2, `XCB_Connection *c`'undivert(PARMDIV)', `
    XCB_`$1'_cookie ret;
    XCB_`$2'_Req *out;
undivert(VARDIV)`'dnl
ifelse(PARTQTY, 0, `dnl', `    struct iovec parts[PARTQTY];')

    pthread_mutex_lock(&c->locked);
    out = (XCB_`$2'_Req *) XCB_Alloc_Out(c, (sizeof(*out) + XCB_PAD(sizeof(*out))));

undivert(OUTDIV)`'dnl
ifelse(PARAMQTY, 0, `dnl')
    ret.seqnum = ++c->seqnum;
ifelse(PARTQTY, 0, `dnl', `    XCB_Write(c, parts, PARTQTY);')
ifelse($1, void, `dnl', `    XCB_Add_Reply_Data(c, ret.seqnum);')
    pthread_mutex_unlock(&c->locked);

    return ret;
define(`PARTQTY', 0)define(`PARAMQTY', 0)')')


dnl --- Structure macros ------------------------------------------------------

dnl FIELD, ARRAYFIELD, and POINTERFIELD can be used in either STRUCT or
dnl UNION definitions.

dnl Declares a field of the given type with the given name.
dnl FIELD(type, name)
define(`FIELD', `PUSHDIV(STRUCTDIV)dnl
    `$1' `$2';
define(`FIELDQTY', eval(1+FIELDQTY))dnl
POPDIV()dnl')

dnl Declares an array field with the given quantity of elements of the
dnl given type.
dnl ARRAYFIELD(type, name, quantity)
define(`ARRAYFIELD', `PUSHDIV(STRUCTDIV)dnl
    `$1' `$2'[`$3'];
define(`FIELDQTY', eval(1+FIELDQTY))dnl
POPDIV()dnl')

dnl Declares a field with the given name which is a pointer to the given type.
dnl POINTERFIELD(type, name)
define(`POINTERFIELD', `PUSHDIV(STRUCTDIV)dnl
    `$1' *`$2';
define(`FIELDQTY', eval(1+FIELDQTY))dnl
POPDIV()dnl')

dnl STRUCT(name, 1 or more FIELDs)
define(`STRUCT', `PUSHDIV(-1)
$2
define(`FIELDQTY',0)
POPDIV()dnl
_H`'typedef struct $1 {
_H`'undivert(STRUCTDIV)dnl
_H`'} $1;
_C`'PUSHDIV(-1)undivert(STRUCTDIV)POPDIV()_H')

dnl STATICSTRUCT(name, 1 or more FIELDs)
define(`STATICSTRUCT', `PUSHDIV(-1)
$2
define(`FIELDQTY',0)
POPDIV()dnl
_C`'typedef struct $1 {
_C`'undivert(STRUCTDIV)dnl
_C`'} $1;
_H`'PUSHDIV(-1)undivert(STRUCTDIV)POPDIV()_C')

dnl UNION(name, 1 or more FIELDs)
define(`UNION', `PUSHDIV(-1)
$2
define(`FIELDQTY',0)
POPDIV()dnl
_H`'typedef union $1 {
_H`'undivert(STRUCTDIV)dnl
_H`'} $1;
_C`'PUSHDIV(-1)undivert(STRUCTDIV)POPDIV()_H')

dnl Declares a struct named XCB_<name>_cookie with a single "int seqnum"
dnl field.
dnl COOKIETYPE(name)
define(`COOKIETYPE', `STRUCT(XCB_$1_cookie, `FIELD(int, `seqnum')')')

dnl XCBGEN(header name)
define(`XCBGEN', `dnl
`/*'
 * This file generated automatically from __file__ by xcbgen.m4 using m4.
 * Edit at your peril.
` */'

_H`'#ifndef __$1_H
_H`'#define __$1_H
_C`'#include "patsubst(__file__, `\.m4$', `.h')"')

dnl ENDXCBGEN()
define(`ENDXCBGEN', `_H`'#endif')

divert(0)`'dnl
