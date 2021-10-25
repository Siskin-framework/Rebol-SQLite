REBOL [
	title: "SQLite module builder"
	type: module
]

cmd-words: []
arg-words: []

commands: [
	init-words: [cmd-words [block!] arg-words [block!]]
	;--------------------------

	info: [
		{Returns info about SQLite extension library}
		/of handle [handle!] {SQLite Extension handle}
	]
	open: [
		{Open a new database connection}
		file [file!]
	]
	exec: [
		{Run zero or more semicolon-separate SQL statements}
		db   [handle!] "sqlite-db"
		sql  [string!] "statements"
	]
	trace: [
		{Trace debug output}
		db   [handle!] "sqlite-db"
		mask [integer!]
	]
	prepare: [
		"Prepare SQL statement"
		db   [handle!] "sqlite-db"
		sql  [string!] "statement"
	]
	reset: [
		"Reset prepared statement"
		stmt [handle!] "sqlite-stmt"
	]
	step: [
		"Execute prepared statement"
		stmt [handle!] "sqlite-stmt"
		/rows "Multiple times if there is enough rows in the result"
		 count [integer!]
		/with
		 parameters [block!]
	]
	close: [
		{Close database connection}
		db   [handle!] "sqlite-db"
	]

	;--------------------------
]


header: {REBOL [Title: {Rebol SQLite Extension} Type: module Exports: []]}
enum-commands:  {enum sqlite_commands ^{}
enum-cmd-words: {enum words_sqlite_cmd ^{W_SQLITE_CMD_0,}
enum-arg-words: {enum words_sqlite_arg ^{W_SQLITE_ARG_0,}
func-commands: clear {}

foreach word cmd-words [
	word: uppercase form word
	replace/all word #"-" #"_"
	append enum-cmd-words ajoin ["^/^-W_SQLITE_CMD_" word #","]
]
foreach word arg-words [
	word: uppercase form word
	replace/all word #"-" #"_"
	append enum-arg-words ajoin ["^/^-W_SQLITE_ARG_" word #","]
]

foreach [name spec] commands [
	name: form name
	append header ajoin [lf name ": command " mold/flat spec]

	replace/all name #"-" #"_"
	append func-commands ajoin ["^/int cmd_sqlite_" name "(RXIFRM* frm, void* reb_ctx);"]
	append enum-commands ajoin ["^/^-CMD_SQLITE_" uppercase name #","]
]

new-line/all cmd-words false
new-line/all arg-words false
append header rejoin [{^/init-words words: } mold cmd-words #" " mold arg-words]
append header {^/protect/hide 'init-words}

;print header

out: make string! 2000
append out {// auto-generated file, do not modify! //

#include "sqlite-command.h"

#define MIN_REBOL_VER 3
#define MIN_REBOL_REV 5
#define MIN_REBOL_UPD 4
#define VERSION(a, b, c) (a << 16) + (b << 8) + c
#define MIN_REBOL_VERSION VERSION(MIN_REBOL_VER, MIN_REBOL_REV, MIN_REBOL_UPD)

extern REBCNT Handle_SQLiteDB;
extern REBCNT Handle_SQLiteSTMT;

}
append out join enum-commands "^/};^/"
append out join enum-cmd-words "^/};^/"
append out join enum-arg-words "^/};^/"
append out func-commands
append out {^/^/#define EXT_SQLITE_INIT_CODE \}


foreach line split header lf [
	replace/all line #"^"" {\"}
	append out ajoin [{^/^-"} line {\n"\}] 
]
append out "^/"


;print out

write %sqlite-rebol-extension.h out
