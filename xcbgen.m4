dnl
dnl generate XCB C code
dnl Bart & Jamey 9/2001
dnl
divert(-1)

dnl --- General definitions ---------------------------------------------------

m4wrap(`divert(-1)undivert')

dnl Use C-style comments.
changecom(`/*', `*/')

define(`pushdiv', `pushdef(`DIVNUM',divnum)divert($1)')
define(`popdiv', `divert(DIVNUM)popdef(`DIVNUM')')

define(`TAB', `')
define(`INDENT', `pushdef(`TAB', `    'TAB)')
define(`UNINDENT', `popdef(`TAB')')

ifdef(`_H', , `define(`_H', `dnl')')
ifdef(`_C', , `define(`_C', `dnl')')

dnl FUNCTION(return type/name, params, body)
define(`FUNCTION', `dnl
$1`('$2`)'_H;
_C
_H`'pushdiv(-1)
{INDENT()dnl
'$3`dnl
}UNINDENT()
_H`'popdiv()dnl')

dnl STATICFUNCTION(return type/name, params, body)
define(`STATICFUNCTION', `dnl
_C`'static $1`('$2`)'
_H`'pushdiv(-1)
{INDENT()dnl
'$3`dnl
}UNINDENT()
_H`'popdiv()dnl')

define(`ALLOC', `dnl
TAB()$2 = ($1 *) malloc(($3) * sizeof($1));
TAB()assert($2);')
define(`REALLOC', `dnl
TAB()$2 = ($1 *) realloc($2, ($3) * sizeof($1));
TAB()assert($2);')

define(`PARMDIV',   1)
define(`OUTDIV',    2)
define(`VARDIV',    3)
define(`STRUCTDIV', 4)

define(`PARTQTY',0)
define(`PARAMQTY',0)

dnl --- Request/Response macros -----------------------------------------------

define(`VALUEPARAM', `pushdiv(OUTDIV)
TAB()out->`$2' = `$2';
TAB()out->length += XCB_Ones(`$2');
TAB()parts[PARTQTY].iov_base = `$3';
TAB()parts[PARTQTY].iov_len = XCB_Ones(`$2') * 4;
define(`PARTQTY', eval(1+PARTQTY))dnl
divert(PARMDIV), $1 `$2', CARD32 *`$3'dnl
popdiv()')

define(`LISTPARAM', `pushdiv(OUTDIV)
TAB()out->length += (`$3') * sizeof($1) / 4;
TAB()parts[PARTQTY].iov_base = `$2';
TAB()parts[PARTQTY].iov_len = (`$3') * sizeof($1);
define(`PARTQTY', eval(1+PARTQTY))dnl
divert(PARMDIV), $1 *`$2'dnl
popdiv()')

define(`STRLENPARAM', `pushdiv(OUTDIV)dnl
TAB()out->`$2' = `$2' = strlen(`$1');
divert(VARDIV)dnl
TAB()int `$2';
popdiv()')

define(`LOCALPARAM', `pushdiv(PARMDIV), $1 `$2'popdiv()')

define(`EXPRPARAM', `pushdiv(OUTDIV)dnl
TAB()out->`$1' = `$2';
popdiv()')

define(`PARAM', `pushdiv(OUTDIV)dnl
TAB()out->`$2' = `$2';
define(`PARAMQTY', eval(1+PARAMQTY))dnl
divert(PARMDIV), $1 `$2'`'dnl
popdiv()')

dnl VOIDREQUEST(name, 0 or more PARAMs)
define(`VOIDREQUEST',`dnl
pushdiv(-1) INDENT() $2 UNINDENT() popdiv()dnl
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
pushdiv(OUTDIV)dnl
#define `XCB_'REQ`_'THISFIELD`(reply)' (($1 *) (dnl
ifdef(`LASTFIELD', `XCB_'REQ`_'LASTFIELD`(reply) + reply->'LASTLEN, `reply + 1')))
popdiv()define(`LASTFIELD',THISFIELD)define(`LASTLEN',$3)')

define(`UNWRAPREPLYFIELD', `dnl
pushdiv(-1) $1 popdiv()dnl
_H`'undivert(OUTDIV)`'dnl
')

dnl REQUEST(name, 0 or more PARAMs, 0 or more REPLYFIELDs)
define(`REQUEST',`dnl
pushdiv(-1) INDENT() $2 UNINDENT() popdiv()dnl
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

define(`FIELD', `pushdiv(STRUCTDIV)dnl
    $1 $2;
popdiv()dnl')

define(`ARRAYFIELD', `pushdiv(STRUCTDIV)dnl
    $1 $2[$3];
popdiv()dnl')

define(`POINTERFIELD', `pushdiv(STRUCTDIV)dnl
    $1 *$2;
popdiv()dnl')

define(`STRUCT', `pushdiv(-1)
$2
popdiv()dnl
_H`'typedef struct $1 {
_H`'undivert(STRUCTDIV)dnl
_H`'} $1;')

define(`UNION', `pushdiv(-1)
$2
popdiv()dnl
_H`'typedef union $1 {
_H`'undivert(STRUCTDIV)dnl
_H`'} $1;')

define(`COOKIETYPE', `STRUCT(XCB_$1_cookie, `FIELD(int, `seqnum')')')

define(`HEADERDEF', `translit(__file__, `a-z.', `A-Z_')')
define(`STARTHEADER', `dnl
_H`'#ifndef HEADERDEF
_H`'#define HEADERDEF
_H
m4wrap(`_H
_H`'#endif /* 'HEADERDEF` */
')dnl')

divert(0)`'dnl
