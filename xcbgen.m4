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
define(`PARTQTY',  0)  dnl Count of variable length elements in request
define(`PARAMQTY', 0)  dnl Count of parameters to request (currently tests
                       dnl only for zero/nonzero)


dnl -- Request/Response macros

dnl HERE

define(`VALUEPARAM', `PUSHDIV(OUTDIV)
TAB()out->`$2' = `$2';
TAB()out->length += XCB_Ones(`$2');
TAB()parts[PARTQTY].iov_base = `$3';
TAB()parts[PARTQTY].iov_len = XCB_Ones(`$2') * 4;
define(`PARTQTY', eval(1+PARTQTY))dnl
divert(PARMDIV), $1 `$2', CARD32 *`$3'dnl
POPDIV()')

define(`LISTPARAM', `PUSHDIV(OUTDIV)
TAB()out->length += (`$3') * sizeof($1) / 4;
TAB()parts[PARTQTY].iov_base = `$2';
TAB()parts[PARTQTY].iov_len = (`$3') * sizeof($1);
define(`PARTQTY', eval(1+PARTQTY))dnl
divert(PARMDIV), $1 *`$2'dnl
POPDIV()')

define(`STRLENPARAM', `PUSHDIV(OUTDIV)dnl
TAB()out->`$2' = `$2' = strlen(`$1');
divert(VARDIV)dnl
TAB()int `$2';
POPDIV()')

define(`LOCALPARAM', `PUSHDIV(PARMDIV), $1 `$2'POPDIV()')

define(`EXPRPARAM', `PUSHDIV(OUTDIV)dnl
TAB()out->`$1' = `$2';
POPDIV()')

define(`PARAM', `PUSHDIV(OUTDIV)dnl
TAB()out->`$2' = `$2';
define(`PARAMQTY', eval(1+PARAMQTY))dnl
divert(PARMDIV), $1 `$2'`'dnl
POPDIV()')

dnl VOIDREQUEST(name, 0 or more PARAMs)
define(`VOIDREQUEST',`dnl
PUSHDIV(-1) INDENT() $2 UNINDENT() POPDIV()dnl
FUNCTION(`XCB_void_cookie XCB_'$1, `XCB_Connection *c`'undivert(PARMDIV)', `
#ifndef sz_x`$1'Req
#define x`$1'Req ifelse(PARAMQTY,1,`xResourceReq',`xReq')
#endif

    XCB_void_cookie ret;
    x`$1'Req *out;
undivert(VARDIV)`'dnl
ifelse(PARTQTY,0,`dnl',`    struct iovec parts[PARTQTY];')

    pthread_mutex_lock(&c->locked);
    if(c->n_outqueue > sizeof(c->outqueue) - SIZEOF(x`$1'Req))
        XCB_Flush(c);
    assert(c->n_outqueue <= sizeof(c->outqueue) - SIZEOF(x`$1'Req));

    out = (x`$1'Req *) (c->outqueue + c->n_outqueue);
    out->reqType = X_`$1';
    out->length = SIZEOF(x`$1'Req) / 4;
    c->n_outqueue += SIZEOF(x`$1'Req);

undivert(OUTDIV)dnl
ifelse(PARAMQTY,0,`dnl')
    ret.seqnum = ++c->seqnum;
ifelse(PARTQTY,0,`dnl',`    XCB_Write(c, parts, PARTQTY);')
    pthread_mutex_unlock(&c->locked);

    return ret;
define(`PARTQTY',0)dnl
define(`PARAMQTY',0)dnl
')')

dnl REPLYFIELD(field type, field name, opt length)
define(`REPLYFIELD', `define(`THISFIELD', translit($2,`a-z',`A-Z'))
PUSHDIV(OUTDIV)dnl
#define `XCB_'REQ`_'THISFIELD`(reply)' (($1 *) (dnl
ifdef(`LASTFIELD', `XCB_'REQ`_'LASTFIELD`(reply) + reply->'LASTLEN, `reply + 1')))
POPDIV()define(`LASTFIELD',THISFIELD)define(`LASTLEN',$3)')

define(`UNWRAPREPLYFIELD', `dnl
PUSHDIV(-1) $1 POPDIV()dnl
_H`'undivert(OUTDIV)`'dnl
')

dnl REQUEST(name, 0 or more PARAMs, 0 or more REPLYFIELDs)
define(`REQUEST',`dnl
PUSHDIV(-1) INDENT() $2 UNINDENT() POPDIV()dnl
COOKIETYPE($1)
_H
FUNCTION(`XCB_'$1`_cookie XCB_'$1, `XCB_Connection *c`'undivert(PARMDIV)', `
#ifndef sz_x`$1'Req
#define x`$1'Req ifelse(PARAMQTY,1,`xResourceReq',`xReq')
#endif

    XCB_`'$1`'_cookie ret;
    x`$1'Req *out;
undivert(VARDIV)`'dnl
    XCB_Reply_Data *reply_data;
ifelse(PARTQTY,0,`dnl',`    struct iovec parts[PARTQTY];')

    pthread_mutex_lock(&c->locked);
    if(c->n_outqueue > sizeof(c->outqueue) - SIZEOF(x`$1'Req))
        XCB_Flush(c);
    assert(c->n_outqueue <= sizeof(c->outqueue) - SIZEOF(x`$1'Req));

    out = (x`$1'Req *) (c->outqueue + c->n_outqueue);
    out->reqType = X_`$1';
    out->length = SIZEOF(x`$1'Req) / 4;
    c->n_outqueue += SIZEOF(x`$1'Req);

undivert(OUTDIV)dnl
ifelse(PARAMQTY,0,`dnl')
    ret.seqnum = ++c->seqnum;
ifelse(PARTQTY,0,`dnl',`    XCB_Write(c, parts, PARTQTY);')
ALLOC(XCB_Reply_Data, reply_data, 1)
    reply_data->pending = 0;
    reply_data->received = 0;
    reply_data->error = 0;
    reply_data->seqnum = ret.seqnum;
    reply_data->data = 0;
    XCB_Add_Reply_Data(c, reply_data);
    pthread_mutex_unlock(&c->locked);

    return ret;
define(`PARTQTY',0)dnl
define(`PARAMQTY',0)dnl
')

/* It is the caller''`s responsibility to free the returned
 * x'$1`Reply object. */
FUNCTION(`x'$1`Reply *XCB_'$1`_Reply', dnl
`XCB_Connection *c, XCB_'$1`_cookie cookie, xError **e', `
    return (x'$1`Reply *) XCB_Wait_Seqnum(c, cookie.seqnum, e);
')`'dnl
pushdef(`REQ', translit($1, `a-z', `A-Z'))dnl
UNWRAPREPLYFIELD(`$3')`'dnl
undefine(`LASTFIELD')undefine(`LASTLEN')popdef(`REQ')dnl')

dnl --- Structure macros ------------------------------------------------------

define(`FIELD', `PUSHDIV(STRUCTDIV)dnl
    $1 $2;
POPDIV()dnl')

define(`ARRAYFIELD', `PUSHDIV(STRUCTDIV)dnl
    $1 $2[$3];
POPDIV()dnl')

define(`POINTERFIELD', `PUSHDIV(STRUCTDIV)dnl
    $1 *$2;
POPDIV()dnl')

define(`STRUCT', `PUSHDIV(-1)
$2
POPDIV()dnl
_H`'typedef struct $1 {
_H`'undivert(STRUCTDIV)dnl
_H`'} $1;')

define(`UNION', `PUSHDIV(-1)
$2
POPDIV()dnl
_H`'typedef union $1 {
_H`'undivert(STRUCTDIV)dnl
_H`'} $1;')

define(`COOKIETYPE', `STRUCT(XCB_$1_cookie, `FIELD(int, `seqnum')')')

define(`XCBGEN', `dnl
`/*'
 * This file generated automatically from __file__ by xcbgen.m4 using m4.
 * Edit at your peril.
` */'

_H`'#ifndef __$1_H
_H`'#define __$1_H')
define(`ENDXCBGEN', `_H`'#endif')

divert(0)`'dnl
