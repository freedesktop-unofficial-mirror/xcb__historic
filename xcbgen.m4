dnl
dnl generate XCB C code
dnl Bart & Jamey 9/2001
dnl
divert(-1)

dnl --- General definitions ---------------------------------------------------

m4wrap(`divert(-1)undivert')

dnl Use C-style comments.
changecom(`/*', `*/')

define(`pushdiv', `pushdef(`_divnum',divnum)divert($1)')
define(`popdiv', `divert(_divnum)popdef(`_divnum')')

define(`TAB', `')
define(`INDENT', `pushdef(`TAB', `    'TAB)')
define(`UNINDENT', `popdef(`TAB')')

ifdef(`_H', , `define(`_H', `dnl')')
ifdef(`_C', , `define(`_C', `dnl')')

dnl visibility, return type/name, params, body
define(`FUNCTION', `dnl
ifelse(`$1',static,`_C')`'$1`'ifelse($1,,,` ')`'$2`('$3`)'_H;
_C
_H`'pushdiv(-1)
{INDENT()dnl
'$4`dnl
}UNINDENT()
_H`'popdiv()dnl')

define(`ALLOC', `dnl
TAB()$2 = ($1 *) malloc(($3) * sizeof($1));
TAB()assert($2);')
define(`REALLOC', `dnl
TAB()$2 = ($1 *) realloc($2, ($3) * sizeof($1));
TAB()assert($2);')

define(`_parmdiv',1)
define(`_outdiv',2)
define(`_vardiv',3)
define(`_sizediv',4)
define(`_datadiv',5)
define(`_structdiv',6)

define(`_PARTQTY',0)
define(`_PARAMQTY',0)

dnl --- Request/Response macros -----------------------------------------------

define(`VALUEPARAM', `pushdiv(_outdiv)
TAB()out->`$2' = `$2';
TAB()out->length += XCB_Ones(`$2');
TAB()parts[_PARTQTY].iov_base = `$3';
TAB()parts[_PARTQTY].iov_len = XCB_Ones(`$2') * 4;
define(`_PARTQTY', eval(1+_PARTQTY))dnl
divert(_parmdiv), $1 `$2', CARD32 *`$3'dnl
popdiv()')

define(`LISTPARAM', `pushdiv(_outdiv)
TAB()out->length += (`$3') * sizeof($1) / 4;
TAB()parts[_PARTQTY].iov_base = `$2';
TAB()parts[_PARTQTY].iov_len = (`$3') * sizeof($1);
define(`_PARTQTY', eval(1+_PARTQTY))dnl
divert(_parmdiv), $1 *`$2'dnl
popdiv()')

define(`STRLENPARAM', `pushdiv(_outdiv)dnl
TAB()out->`$2' = strlen(`$1');
popdiv()')

define(`LOCALPARAM', `pushdiv(_parmdiv), $1 `$2'popdiv()')

define(`PARAM', `pushdiv(_outdiv)dnl
TAB()out->`$2' = `$2';
define(`_PARAMQTY', eval(1+_PARAMQTY))dnl
divert(_parmdiv), $1 `$2'`'dnl
popdiv()')

dnl return type, name, 0+ PARAMs
define(`REQUEST',`dnl
pushdiv(-1) INDENT() $3 UNINDENT() popdiv()dnl
ifelse($1, void, `dnl', `COOKIETYPE($1)
_H')
FUNCTION(`', `XCB_'$1`_cookie XP_'$2, `XCB_Connection *c`'undivert(_parmdiv)', `
`#'ifndef sz_x`$2'Req
ifelse(_PARAMQTY,1,`dnl
`#'define x`$2'Req xResourceReq',`dnl
`#'define x`$2'Req xReq')
`#'endif

    XCB_`'$1`'_cookie ret;
    x`$2'Req *out;
ifelse($1,void,`dnl',`    XCB_Reply_Data *reply_data;')
ifelse(_PARTQTY,0,`dnl',`    struct iovec parts[_PARTQTY];')

    pthread_mutex_lock(&c->locked);
    if(c->n_outqueue > sizeof(c->outqueue) - SIZEOF(x`$2'Req))
        XCB_Flush(c);
    assert(c->n_outqueue <= sizeof(c->outqueue) - SIZEOF(x`$2'Req));

    out = (x`$2'Req *) (c->outqueue + c->n_outqueue);
    out->reqType = X_`$2';
    out->length = SIZEOF(x`$2'Req) / 4;
    c->n_outqueue += SIZEOF(x`$2'Req);

undivert(_outdiv)dnl
ifelse(_PARAMQTY,0,`dnl')
    ret.seqnum = ++c->seqnum;
ifelse(_PARTQTY,0,`dnl',`    XCB_Write(c, parts, _PARTQTY);')
ifelse($1,void,,`dnl
ALLOC(XCB_Reply_Data, reply_data, 1)
    reply_data->pending = 0;
    reply_data->received = 0;
    reply_data->error = 0;
    reply_data->seqnum = ret.seqnum;
    reply_data->data = 0;
    XCB_Add_Reply_Data(c, reply_data);
')dnl
    pthread_mutex_unlock(&c->locked);

    return ret;
define(`_PARTQTY',0)dnl
define(`_PARAMQTY',0)dnl
')
ifelse($1, void, `pushdiv(-1)')
/* It is the caller''`s responsibility to free the returned
 * x'$1`Reply object. */
FUNCTION(`', `x'$1`Reply *XP_'$1`_Get_Reply', dnl
`XCB_Connection *c, XCB_'$1`_cookie cookie, xError **e', `
    return (x'$1`Reply *) XCB_Wait_Seqnum(c, cookie.seqnum, e);
')
ifelse($1, void, `popdiv()')dnl')

dnl --- Structure macros ------------------------------------------------------

define(`FIELD', `pushdiv(_structdiv)dnl
    $1 $2;
popdiv()dnl')

define(`ARRAYFIELD', `pushdiv(_structdiv)dnl
    $1 $2[$3];
popdiv()dnl')

define(`POINTERFIELD', `pushdiv(_structdiv)dnl
    $1 *$2;
popdiv()dnl')

define(`STRUCT', `pushdiv(-1)
$2
popdiv()dnl
_H`'typedef struct $1 {
_H`'undivert(_structdiv)dnl
_H`'} $1;')

define(`UNION', `pushdiv(-1)
$2
popdiv()dnl
_H`'typedef union $1 {
_H`'undivert(_structdiv)dnl
_H`'} $1;')

define(`COOKIETYPE', `STRUCT(XCB_$1_cookie, `FIELD(int, `seqnum')')')

define(`_HEADERDEF', `translit(__file__, `a-z.', `A-Z_')')

define(`STARTHEADER', `dnl
_H`'#ifndef _HEADERDEF
_H`'#define _HEADERDEF
_H
m4wrap(`_H
_H`'#endif /* '_HEADERDEF` */
')dnl')

divert(0)`'dnl
