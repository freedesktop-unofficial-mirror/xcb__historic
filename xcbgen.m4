dnl
dnl generate XCB C code
dnl Bart & Jamey 9/2001
dnl
divert(-1)

dnl --- General definitions ---------------------------------------------------

define(`TAB', `')
define(`INDENT', `pushdef(`TAB', `    'TAB)')
define(`UNINDENT', `popdef(`TAB')')

define(`ALLOC', `dnl
TAB()$2 = ($1 *) malloc(($3) * sizeof($1));
TAB()assert($2);')
define(`REALLOC', `dnl
TAB()$2 = ($1 *) realloc($2, ($3) * sizeof($1));
TAB()assert($2);')

define(`_outdiv',-1)
define(`_index',0)
define(`_SIZE',0)
define(`_FIRST',1)
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

BASETYPE(unsigned char,1,`dnl
TAB()buf[INDEX] = (unsigned char) (`$1');',`dnl
TAB()`$1' = buf[INDEX];')
BASETYPE(unsigned short,2,`dnl
TAB()buf[INDEX] = (unsigned char) (`$1' >> 8);
TAB()buf[INDEX] |= (unsigned char) (`$1');',`dnl
TAB()`$1' = buf[INDEX] << 8;
TAB()`$1' |= buf[INDEX];')
BASETYPE(unsigned int,4,`dnl
TAB()buf[INDEX] = (unsigned char) (`$1' >> 24);
TAB()buf[INDEX] |= (unsigned char) (`$1' >> 16);
TAB()buf[INDEX] |= (unsigned char) (`$1' >> 8);
TAB()buf[INDEX] |= (unsigned char) (`$1');',`dnl
TAB()`$1' = buf[INDEX] << 24;
TAB()`$1' |= buf[INDEX] << 16;
TAB()`$1' |= buf[INDEX] << 8;
TAB()`$1' |= buf[INDEX];')
TYPE(unsigned char,signed char)
TYPE(unsigned short,signed short)
TYPE(unsigned int,signed int)

define(`COOKIETYPE', `STRUCT(XCB_$1_cookie, `FIELD(int, `seqnum')')')

dnl --- Request/Response macros -----------------------------------------------

define(`VALUE', `STRUCT($1, `FIELD(XP_CARD32, `mask')')')
define(`VALUECODE', `dnl')

define(`BITMASKPARAM', `pushdef(`_divnum',divnum)dnl
divert(_outdiv)dnl
PACK($1,$2.mask)
    {
        $1 mask = $2.mask;
        for(; mask; mask >>= 1)
            if(mask & 1)
                varsize += 4;
    }
define(`_VARSIZE',1)dnl
divert(_divnum)popdef(`_divnum')')

define(`VALUEPARAM', `pushdef(`_divnum',divnum)dnl
divert(_outdiv)`'dnl
REALLOC(unsigned char, buf, _SIZE + varsize)
    /* pack in values from `$1' here */
divert(1)`'ifelse(_FIRST,1,define(`_FIRST',0),`, ')$1 $2`'dnl
divert(_divnum)popdef(`_divnum')')

define(`PARAM', `pushdef(`_divnum',divnum)dnl
divert(_outdiv)`'PACK($1,`$2')
divert(1)`'ifelse(_FIRST,1,define(`_FIRST',0),`, ')$1 `$2'`'dnl
divert(_divnum)popdef(`_divnum')')

dnl return type, name, opcode, data, and a collection of parameters.
define(`REQUEST',`divert(-1)INDENT()
define(`_outdiv',2)
define(`_index',0) divert(2)PACK(XP_CARD8,$3)
divert(-1) ifelse($4,unused,,`PARAM(`XP_CARD8',`$4')')
define(`_index',4) define(`_SIZE',4) $5 define(`_THISSIZE', _SIZE)
define(`_index',2)
divert(2)PACK(XP_CARD16,dnl
ifelse(_VARSIZE,1,(eval(_THISSIZE/4) + varsize / 4),eval(_THISSIZE/4)))
define(`_outdiv',-1)UNINDENT()divert(0)dnl
FUNCTION(`', `XCB_'$1`_cookie XP_'$2, `XCB_Connection *c, undivert(1)', `
    XCB_`'$1`'_cookie ret;
ifelse(_VARSIZE,1,`    int varsize = 0;',`dnl')
    unsigned char *buf;
ALLOC(unsigned char, buf, _THISSIZE)
undivert(2)dnl
    XCB_Connection_Lock(c);
    ret.seqnum = XCB_Write(c, buf, ifelse(_VARSIZE,1,_THISSIZE + varsize,_THISSIZE));
    XCB_Connection_Unlock(c);
    free(buf);
    return ret;
')define(`_FIRST',1)define(`_VARSIZE',0)')

dnl --- Structure macros ------------------------------------------------------

define(`FIELD', `divert(1)dnl
    $1 $2;
divert(-1)
ifelse(_BASESTRUCT,1,,`
dnl    define(`_SIZE', eval(SIZEOF($1)+_SIZE))
    define(`_UNPACKSTRUCT', defn(`_UNPACKSTRUCT')UNPACK($1,$`'1.$2)
)
')
')

define(`ARRAYFIELD', `divert(1)dnl
    $1 $2[$3];
divert(-1)
ifelse(_BASESTRUCT,1,,`define(`_SIZE', eval(SIZEOF($1)*$3+_SIZE))')
')

define(`POINTERFIELD', `divert(1)dnl
    $1 *$2;
divert(-1)
')

define(`LISTFIELD', defn(`POINTERFIELD'))

define(`STRUCT', `divert(-1)
define(`_index',0) define(`_SIZE',0)
define(`_UNPACKSTRUCT',`')
pushdef(`TAB', ``TAB()'') dnl delay evaluation of tabs
$2
popdef(`TAB')
define(_UNPACK($1),defn(`_UNPACKSTRUCT')`dnl') undefine(`_UNPACKSTRUCT')
define(_SIZEOF($1), _SIZE)
divert(0)_STRUCT($1, `undivert(1)')')

m4wrap(`divert(-1)undivert')

divert(0)`'dnl
