dnl Copyright (C) 2001-2002 Bart Massey and Jamey Sharp.
dnl All Rights Reserved.  See the file COPYING in this directory
dnl for licensing information.
dnl
dnl macros-c.m4: Macros for generating C code
divert(-1) dnl Discard any text until a divert(0).

dnl -- Implementations of macros specified in global macros.m4

define(`REQUIRE', `#include <JOIN(`/', $@).h>')

dnl ENUM(type name, name list)
define(`ENUM', `pushdef(`ENUMNAME', `$1')TYPEDEF(`enum $1 {
ENUMLOOP(shift($@))dnl
}', `$1')popdef(`ENUMNAME')')
define(`ENUMLOOP', `ifelse($1, , , `    ENUMNAME`$1',
ENUMLOOP(shift($@))')')

dnl PAD(bytes)
define(`PAD', `ARRAYFIELD(`CARD8', `pad'PADQTY, `$1')
define(`PADQTY', eval(1+PADQTY))
ifelse(FIELDQTY, 2, `LENGTHFIELD()')')

dnl Declares a field of the given type with the given name.
dnl FIELD(type, name)
define(`FIELD', `PUSHDIV(STRUCTDIV)dnl
    `$1' `$2';
POPDIV()define(`FIELDQTY', eval(1+FIELDQTY))')

dnl Declares an array field with the given quantity of elements of the
dnl given type.
dnl ARRAYFIELD(type, name, quantity)
define(`ARRAYFIELD', `PUSHDIV(STRUCTDIV)dnl
    `$1' `$2'[`$3'];
POPDIV()define(`FIELDQTY', eval(1+FIELDQTY))')

dnl Declares a field with the given name which is a pointer to the given type.
dnl POINTERFIELD(type, name)
define(`POINTERFIELD', `PUSHDIV(STRUCTDIV)dnl
    `$1' *`$2';
POPDIV()define(`FIELDQTY', eval(1+FIELDQTY))')


dnl -- Language-specific macros

dnl Use C-style comments.
changecom(`/*', `*/')

dnl COMMENT(text)
define(`COMMENT', `/* '`$@'` */')


dnl Exactly one of _H and _C should be set on the command line.
dnl When _H is set, _C lines will be thrown away.
dnl Similarly, when _C is set, _H lines will be thrown away.
dnl Stuff that belongs in header files only should be
dnl prefixed with _H, stuff that belongs in .c files only should
dnl be prefixed with _C.
dnl Note that the define()s are in the else part of the ifdef.
dnl Do not make the obvious change without careful thought.
define(`HEADERONLY', `PUSHDIV(-1) $1
POPDIV()')
ifdef(`_H', `define(`HEADERONLY', `$1')', `define(`_H', `dnl')')
define(`SOURCEONLY', `PUSHDIV(-1) $1
POPDIV()')
ifdef(`_C', `define(`SOURCEONLY', `$1')', `define(`_C', `dnl')')


dnl Declare a C pre-processor #define.
dnl CPPDEFINE(name, expansion)
define(`CPPDEFINE', `#define `$1' `$2'')

dnl Declare a C pre-processor #undef.
dnl CPPUNDEF(name)
define(`CPPUNDEF', `#undef `$1'')

dnl CONSTANT(type, name, value)
define(`CONSTANT', `CPPDEFINE(`$2', `$3')')


dnl Declare a C function.
dnl Note that this macro also sticks a declaration
dnl in the header file.
dnl FUNCTION(return type and function name, params, body)
define(`FUNCTION', `dnl
$1($2)HEADERONLY(;)SOURCEONLY(`
{INDENT()dnl
$3}UNINDENT()')')

dnl Declare a C function local to the .c file.
dnl The header file is not affected.
dnl STATICFUNCTION(return type and function name, params, body)
define(`STATICFUNCTION', `SOURCEONLY(
`static $1($2)
{INDENT()dnl
$3}UNINDENT()')')

dnl Declare a C function which should be compiled inline if possible.
dnl TODO: fallback to a regular function if inline is not supported by
dnl       the compiler.
dnl INLINEFUNCTION(return type and function name, params, body)
define(`INLINEFUNCTION', `HEADERONLY(
`static inline $1($2)
{INDENT()dnl
$3}UNINDENT()')')


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


dnl -- Type macros

dnl TYPEDEF(old name, new name)
define(`TYPEDEF', `HEADERONLY(`typedef $1 $2;')')

dnl Holds body of structure declared with STRUCT or UNION macros
define(`STRUCTDIV', ALLOCDIV)

dnl PAD, FIELD, ARRAYFIELD, and POINTERFIELD can be used in either STRUCT or
dnl UNION definitions.
UNIMPLEMENTED(`FIELDQTY')
UNIMPLEMENTED(`PADQTY')

dnl STRUCT(name, 1 or more FIELDs)
define(`STRUCT', `PUSHDIV(-1)
pushdef(`FIELDQTY', 0) pushdef(`PADQTY', 0)
$2
popdef(`PADQTY') popdef(`FIELDQTY')
POPDIV()TYPEDEF(`struct $1 {
undivert(STRUCTDIV)dnl
}', `$1')')

dnl STATICSTRUCT(name, 1 or more FIELDs)
define(`STATICSTRUCT', `PUSHDIV(-1)
pushdef(`FIELDQTY', 0) pushdef(`PADQTY', 0)
$2
popdef(`PADQTY') popdef(`FIELDQTY')
POPDIV()dnl
HEADERONLY(`typedef struct `$1' `$1';')dnl
SOURCEONLY(`struct `$1' {
undivert(STRUCTDIV)dnl
};')')

dnl UNION(name, 1 or more FIELDs)
define(`UNION', `PUSHDIV(-1)
pushdef(`FIELDQTY', 0) pushdef(`PADQTY', 0)
$2
popdef(`PADQTY') popdef(`FIELDQTY')
POPDIV()TYPEDEF(`union $1 {
undivert(STRUCTDIV)dnl
}', `$1')')

dnl CHAR(char-literal)
changequote([,])
define([CHAR],['$1'])
changequote(`,')

divert(0)`'dnl
