REBOL [
	title: "SQLite module builder"
	type: module
]

;- all extension command specifications ----------------------------------------
commands: [
	;init-words: [cmd-words [block!] arg-words [block!]]

	info: [
		{Returns info about SQLite extension library}
		/of handle [handle!] {SQLite Extension handle}
	]
	open: [
		{Opens a new database connection}
		file [file!]
	]
	exec: [
		{Runs zero or more semicolon-separate SQL statements}
		db   [handle!] "sqlite-db"
		sql  [string!] "statements"
	]
	eval: [
		{...}
		db    [handle!] "sqlite-db"
		query [string! block! handle!] "semicolon-separated statements, a single query with parameters or a prepared statement"
	]
	last-insert-id: [
		"Returns the rowid of the most recent successful INSERT into a rowid table or virtual table on database connection"
		db    [handle!] "sqlite-db"
	]
	finalize: [
		"Deletes prepared statement"
		stmt [handle!] "sqlite-stmt"
	]
	trace: [
		{Traces debug output}
		db   [handle!] "sqlite-db"
		mask [integer!]
	]
	prepare: [
		"Prepares SQL statement"
		db   [handle!] "sqlite-db"
		sql  [string!] "statement"
	]
	reset: [
		"Resets prepared statement"
		stmt [handle!] "sqlite-stmt"
	]
	step: [
		"Executes prepared statement"
		stmt [handle!] "sqlite-stmt"
		/rows "Multiple times if there is enough rows in the result"
		 count [integer!]
		/with
		 parameters [block!]
	]
	close: [
		{Closes a database connection}
		db   [handle!] "sqlite-db"
	]

	initialize: [
		{Initializes the SQLite library}
	]
	shutdown: [
		{Deallocate any resources that were allocated}
	]
]

;-------------------------------------- ----------------------------------------
reb-code: rejoin[
	{REBOL [Title: "Rebol SQLite Extension"}
	{ Name: sqlite Type: module Exports: []}
	{ Version: 3.42.0.1}
	{ Author: Oldes}
	{ Date: } now
	{ License: Apache-2.0}
	{ Url: https://github.com/Siskin-framework/Rebol-SQLite}
	#"]"
]
enu-commands:  "" ;; command name enumerations
cmd-declares:  "" ;; command function declarations
cmd-dispatch:  "" ;; command functionm dispatcher

;- generate C and Rebol code from the command specifications -------------------
foreach [name spec] commands [
	append reb-code ajoin [lf name ": command "]
	new-line/all spec false
	append/only reb-code mold spec

	name: form name
	replace/all name #"-" #"_"
	
	append enu-commands ajoin ["^/^-CMD_SQLITE_" uppercase copy name #","]

	append cmd-declares ajoin ["^/int cmd_sqlite_" name "(RXIFRM *frm, void *ctx);"]
	append cmd-dispatch ajoin ["^-cmd_sqlite_" name ",^/"]
]

;- additional Rebol initialization code ----------------------------------------
;append reb-code rejoin [{^/init-words words: } mold cmd-words #" " mold arg-words]
;append reb-code {^/protect/hide 'init-words}
;print reb-code

;- convert Rebol code to C-string ----------------------------------------------
init-code: copy ""
foreach line split reb-code lf [
	replace/all line #"^"" {\"}
	append init-code ajoin [{\^/^-"} line {\n"}] 
]

;-- C file templates -----------------------------------------------------------
header: next {
//
// Rebol/SQLite extension
// auto-generated file, do not modify! //

#include "sqlite-command.h"

#define MIN_REBOL_VER 3
#define MIN_REBOL_REV 10
#define MIN_REBOL_UPD 2
#define VERSION(a, b, c) (a << 16) + (b << 8) + c
#define MIN_REBOL_VERSION VERSION(MIN_REBOL_VER, MIN_REBOL_REV, MIN_REBOL_UPD)

extern REBCNT Handle_SQLiteDB;
extern REBCNT Handle_SQLiteSTMT;

extern char* error_buffer[255];


enum ext_commands {$enu-commands
};

$cmd-declares

typedef int (*MyCommandPointer)(RXIFRM *frm, void *ctx);

#define EXT_SQLITE_INIT_CODE $init-code

}
;;------------------------------------------------------------------------------
ctable: next {
//
// auto-generated file, do not modify!
//
#include "sqlite-rebol-extension.h"
MyCommandPointer Command[] = {
$cmd-dispatch};
}

;- output generated files ------------------------------------------------------
write %sqlite-rebol-extension.h reword :header self
write %sqlite-commands-table.c  reword :ctable self


