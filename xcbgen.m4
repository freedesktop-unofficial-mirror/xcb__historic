dnl
dnl generate XCB C code
dnl Bart & Jamey 9/2001
dnl
divert(-1)

dnl --- General definitions ---------------------------------------------------

define(`pushdiv', `pushdef(`_divnum',divnum)divert($1)')
define(`popdiv', `divert(_divnum)popdef(`_divnum')')

define(`TAB', `')
define(`INDENT', `pushdef(`TAB', `    'TAB)')
define(`UNINDENT', `popdef(`TAB')')

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

define(`_index',0)
define(`_SIZE',0)
define(`_VARSIZE',0)
define(`_BASESTRUCT',0)

define(`INDEX', `_index`'define(`_index',incr(_index))')
define(`PAD', `define(`_index',eval(_index+$1))define(`_SIZE',eval(_SIZE+$1))')

dnl --- Type definitions ------------------------------------------------------

define(`_PACK', `_PACK_`'translit($1,` ',`_')')
define(`PACK', `define(`_SIZE',eval(SIZEOF($1)+_SIZE))indir(_PACK($1), `$2')')
define(`_UNPACK', `_UNPACK_`'translit($1,` ',`_')')
define(`UNPACK', `define(`_SIZE',eval(SIZEOF($1)+_SIZE))indir(_UNPACK($1), `$2')')
define(`_SIZEOF', `_SIZEOF_`'translit($1,` ',`_')')
define(`SIZEOF', `indir(_SIZEOF($1))')

define(`TYPE', `_TYPE($1, $2)
define(_SIZEOF($2), SIZEOF($1))dnl
define(_PACK($2), defn(_PACK($1)))dnl
define(_UNPACK($2), defn(_UNPACK($1)))dnl')

define(`BASETYPE', `dnl
define(_SIZEOF($1),`$2')dnl
define(_PACK($1),`$3')dnl
define(_UNPACK($1),`$4')dnl')

BASETYPE(char,1,`dnl
TAB()buf[INDEX] = (unsigned char) (`$1');',`dnl
TAB()`$1' = buf[INDEX];')
BASETYPE(short,2,`dnl
TAB()buf[INDEX] = (unsigned char) (`$1' >> 8);
TAB()buf[INDEX] = (unsigned char) (`$1');',`dnl
TAB()`$1' = (buf[INDEX] << 8) | buf[INDEX];')
BASETYPE(int,4,`dnl
TAB()buf[INDEX] = (unsigned char) (`$1' >> 24);
TAB()buf[INDEX] = (unsigned char) (`$1' >> 16);
TAB()buf[INDEX] = (unsigned char) (`$1' >> 8);
TAB()buf[INDEX] = (unsigned char) (`$1');',`dnl
TAB()`$1' = (buf[INDEX] << 24) | (buf[INDEX] << 16) | (buf[INDEX] << 8) | buf[INDEX];')
TYPE(char,unsigned char)
TYPE(short,unsigned short)
TYPE(int,unsigned int)
TYPE(char,signed char)
TYPE(short,signed short)
TYPE(int,signed int)

define(`ENUMVALUE', `pushdiv(_outdiv)dnl
    _ENUMNAME`'_`'$1,
popdiv()')

define(`ENUMTYPE', `pushdiv(-1)
pushdef(`_ENUMNAME', $2)
TYPE($1, $2)
$3
popdef(`_ENUMNAME')
popdiv()dnl
_TYPE(`enum {
undivert(_outdiv)dnl
}', `$2')')

define(`COOKIETYPE', `pushdef(`_BASESTRUCT',1)dnl
STRUCT(XCB_$1_cookie, `FIELD(int, `seqnum')')`'dnl
popdef(`_BASESTRUCT')_H')

dnl --- Request/Response macros -----------------------------------------------

define(`VALUE', `STRUCT($1, `FIELD(XP_CARD32, `mask')')')
define(`VALUECODE', `dnl')

define(`BITMASKPARAM', `pushdiv(_sizediv)dnl
define(`_VARSIZE',1)dnl
    varsize += 4 * XCB_Ones($2.mask);
divert(_outdiv)dnl
PACK($1, `$2'.mask)
popdiv()')

define(`LISTPARAM', `pushdiv(_sizediv)dnl
define(`_VARSIZE',1)dnl
    varsize += (`$3') * SIZEOF($1)dnl
ifelse(eval(SIZEOF($1)%4),0,, ` + XP_PAD((`$3') * SIZEOF($1))');
divert(_outdiv)dnl
ifelse(SIZEOF($1),1,`dnl
    memcpy(buf + _index, $2, (`$3') * SIZEOF($1));
',`dnl
TAB()INDENT(){
TAB()int i;
TAB()unsigned char *tmp = buf;
TAB()buf += _index;
TAB()for(i = 0; i < `$3'; ++i)
TAB()INDENT(){
pushdef(`_index', 0)dnl
PACK($1, `$2'[i])
TAB()buf += _index;
popdef(`_index')dnl
UNINDENT()TAB()}
TAB()buf = tmp;
UNINDENT()TAB()}
')dnl
divert(_parmdiv), $1 *$2`'dnl
popdiv()')

define(`VALUEPARAM', `pushdiv(_outdiv)dnl
    /* pack in values from `$1' here */
divert(_parmdiv), $1 $2`'dnl
popdiv()')

define(`STRLENPARAM', `pushdiv(_vardiv)dnl
    $1 `$3';
divert(_sizediv)dnl
    `$3' = strlen(`$2');
divert(_outdiv)dnl
PACK($1, `$3')
popdiv()')

define(`PARAM', `pushdiv(_outdiv)dnl
PACK($1,`$2')
divert(_parmdiv), $1 `$2'`'dnl
popdiv()')

dnl return type, name, opcode, data, 0+ PARAMs, opt SAVEPARAMs
define(`REQUEST',`pushdiv(-1)
INDENT()
define(`_index',0) divert(_outdiv)PACK(XP_CARD8,$3)
divert(-1) ifelse($4,unused,,`PARAM(`XP_CARD8',`$4')')
define(`_index',4) define(`_SIZE',4) $5 define(`_THISSIZE', _SIZE)
define(`_index',2)
divert(_outdiv)PACK(XP_CARD16,dnl
ifelse(_VARSIZE,1,(eval(_THISSIZE/4) + varsize / 4),eval(_THISSIZE/4)))
UNINDENT()popdiv()dnl
FUNCTION(`', `XCB_'$1`_cookie XP_'$2, `XCB_Connection *c`'undivert(_parmdiv)', `
    XCB_`'$1`'_cookie ret;
ifelse($1,void,`dnl',`    XCB_Reply_Data *reply_data;')
ifelse(_VARSIZE,1,`    int varsize = 0;',`dnl')
    unsigned char *buf;
undivert(_vardiv)dnl

undivert(_sizediv)dnl
ALLOC(unsigned char, buf, ifelse(_VARSIZE,1,_THISSIZE + varsize,_THISSIZE))

undivert(_outdiv)dnl

    XCB_Connection_Lock(c);
    ret.seqnum = XCB_Write(c, buf, ifelse(_VARSIZE,1,_THISSIZE + varsize,_THISSIZE));
ifelse($1,void,,`
ALLOC(XCB_Reply_Data, reply_data, 1)
    reply_data->pending = 0;
    reply_data->received = 0;
    reply_data->reply_handler = XP_`'$1`'_Reply_Handler;
    reply_data->seqnum = ret.seqnum;
    reply_data->data = 0;
    XCB_Add_Reply_Data(c, reply_data);
')dnl
    XCB_Connection_Unlock(c);

    free(buf);
    return ret;
')define(`_VARSIZE',0)')

define(`REPLY', `dnl
COOKIETYPE($1)
_H
STRUCT(XP_`'$1`'_Reply, `
PAD(1) dnl == 1, meaning reply
ifelse($2,unused,`PAD(1)',`FIELD(XP_CARD8, `$2')')
PAD(6) dnl == seqnum followed by reply length
$3
')
_H
/* It is the caller''`s responsibility to free the returned
 * XP_'$1`_Reply object. */
FUNCTION(`', `XP_'$1`_Reply *XP_'$1`_Get_Reply', dnl
`XCB_Connection *c, XCB_'$1`_cookie cookie', `
    return (XP_'$1`_Reply *) XCB_Wait_Seqnum(c, cookie.seqnum);
')
_C
FUNCTION(`', `int XP_'$1`_Reply_Handler', dnl
`XCB_Connection *c, XCB_Reply_Data *r, unsigned char *buf', `
    XP_`'$1`'_Reply *data;
ALLOC(XP_`'$1`'_Reply, data, 1)
UNPACK(XP_`'$1`'_Reply, data)
    r->data = (void *) data;
    r->received = 1;
    return 1;
')')

dnl --- Structure macros ------------------------------------------------------

define(`FIELD', `pushdiv(1)dnl
    $1 $2;
divert(-1)
ifelse(_BASESTRUCT,1,,`
    define(`_UNPACKSTRUCT', defn(`_UNPACKSTRUCT')UNPACK($1,$`'1->$2)
)')
popdiv()dnl')

define(`ARRAYFIELD', `pushdiv(1)dnl
    $1 $2[$3];
divert(-1)
ifelse(_BASESTRUCT,1,,`define(`_SIZE', eval(SIZEOF($1)*$3+_SIZE))')
popdiv()dnl')

define(`POINTERFIELD', `pushdiv(1)dnl
    $1 *$2;
popdiv()dnl')

dnl FIXME: can not nest lists of structs containing lists.
dnl FIXME: can not have more than one list in a struct
define(`LISTFIELD', `pushdiv(1)dnl
    $1 *$2;
divert(-1)
ifelse(_BASESTRUCT,1,,`
define(`_UNPACKSTRUCT', defn(`_UNPACKSTRUCT')`dnl
TAB()INDENT(){
TAB()int i;
TAB()$1 *tmp_`'$2;
TAB()'$`'1` = ('_STRUCTTYPE` *) realloc('$`'1`, sizeof('_STRUCTTYPE`) + sizeof($1) * '$`'1`->$3);
TAB()assert('$`'1`);

TAB()tmp_`'$2 = ($1 *) ((('_STRUCTTYPE` *) '$`'1`) + 1);
TAB()'$`'1`->$2 = tmp_`'$2;

TAB()buf += SIZEOF('_STRUCTTYPE`);
TAB()for(i = 0; i < ('$`'1`->$3); ++i)
TAB()INDENT(){
pushdef(`_index', 0)dnl
UNPACK($1, tmp_`'$2[i])
TAB()buf += _index + XP_PAD(_index);
popdef(`_index')dnl
UNINDENT()TAB()}
UNINDENT()TAB()}
')')
popdiv()dnl')

define(`STRUCT', `pushdiv(-1)
define(`_index',0) define(`_SIZE',0)
pushdef(`_UNPACKSTRUCT',`')
pushdef(`_STRUCTTYPE', $1)
pushdef(`TAB', ``TAB()'') dnl delay evaluation of tabs
$2
popdef(`TAB')
popdef(`_STRUCTTYPE')
define(_UNPACK($1),defn(`_UNPACKSTRUCT')`dnl') popdef(`_UNPACKSTRUCT')
define(_SIZEOF($1), _SIZE)
popdiv()_STRUCT($1, `undivert(1)')')

m4wrap(`divert(-1)undivert')

divert(0)`'dnl
