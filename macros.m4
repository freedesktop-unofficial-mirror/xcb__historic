divert(-1)

dnl -- Generic macros useful in m4

dnl GNU m4 m4wrap() executes argument at end of input.
dnl In this case the argument discards unprocessed diversions.
m4wrap(`divert(-1)undivert')


dnl Push diversion on the diversion stack
dnl PUSHDIV(diversion)
define(`PUSHDIV', `pushdef(`DIVNUM', divnum)divert($1)')

dnl Pop diversion off the diversion stack and discards it
dnl POPDIV()
define(`POPDIV', `divert(DIVNUM)popdef(`DIVNUM')')

dnl Track the diversion numbers which are in use so we can hand out new ones
dnl without conflicting with anything.
define(`LASTDIV', 0)
define(`ALLOCDIV', `define(`LASTDIV', eval(1+LASTDIV))LASTDIV')


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

dnl Join a list of strings with a given string as separator.
dnl JOIN(sep, string, ...)
define(`JOIN', `ifelse(`$3', , `$2', `$2'`$1'`JOIN(`$1', shift(shift($@)))')')


dnl Provide a warning if a macro is called in the wrong context.
dnl UNIMPLEMENTED(macro name)
define(`UNIMPLEMENTED',
`define(`$1', `errprint(__file__:__line__: Macro `$1' not implemented in this context.
)')')


dnl -- Macros which should be implemented in a more specific context

dnl Comma-separated path of the logical package containing the current file.
dnl PACKAGE()
UNIMPLEMENTED(`PACKAGE')

dnl Declare that the file or package is required to compile the current file.
dnl The file extension should not be included.
dnl REQUIRE(package, opt file)
UNIMPLEMENTED(`REQUIRE')

dnl Define a human-readable comment regarding the surrounding context.
dnl COMMENT(text)
UNIMPLEMENTED(`COMMENT')
UNIMPLEMENTED(`DESCRIPTION')

dnl Generates the standard prefix in the output code. The source file name
dnl should not include extension or path.
dnl XCBGEN(source file name)
UNIMPLEMENTED(`XCBGEN')

dnl Generates the standard suffix in the output code.
dnl ENDXCBGEN()
UNIMPLEMENTED(`ENDXCBGEN')

UNIMPLEMENTED(`BEGINEXTENSION')
UNIMPLEMENTED(`ENDEXTENSION')

UNIMPLEMENTED(`COOKIETYPE')
UNIMPLEMENTED(`VOIDREQUEST')
UNIMPLEMENTED(`REQUEST')
UNIMPLEMENTED(`EVENT')
UNIMPLEMENTED(`EVENTCOPY')
UNIMPLEMENTED(`ERROR')
UNIMPLEMENTED(`ERRORCOPY')

UNIMPLEMENTED(`PAD')
UNIMPLEMENTED(`FIELD')
UNIMPLEMENTED(`ARRAYFIELD')
UNIMPLEMENTED(`POINTERFIELD')

dnl XXX: I would like to replace these with a more intuitive set of primitives.
UNIMPLEMENTED(`VALUEPARAM')
UNIMPLEMENTED(`LISTPARAM')
UNIMPLEMENTED(`EXPRFIELD')
UNIMPLEMENTED(`LOCALPARAM')
UNIMPLEMENTED(`PARAM')
UNIMPLEMENTED(`OPCODE')
UNIMPLEMENTED(`REPLY')
UNIMPLEMENTED(`ARRAYREPLY')
UNIMPLEMENTED(`LISTREPLY')

divert(0)`'dnl
