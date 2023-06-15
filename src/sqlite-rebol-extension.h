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


enum ext_commands {
	CMD_SQLITE_INFO,
	CMD_SQLITE_OPEN,
	CMD_SQLITE_EXEC,
	CMD_SQLITE_EVAL,
	CMD_SQLITE_LAST_INSERT_ID,
	CMD_SQLITE_FINALIZE,
	CMD_SQLITE_TRACE,
	CMD_SQLITE_PREPARE,
	CMD_SQLITE_RESET,
	CMD_SQLITE_STEP,
	CMD_SQLITE_CLOSE,
	CMD_SQLITE_COLUMNS,
	CMD_SQLITE_INITIALIZE,
	CMD_SQLITE_SHUTDOWN,
};


int cmd_sqlite_info(RXIFRM *frm, void *ctx);
int cmd_sqlite_open(RXIFRM *frm, void *ctx);
int cmd_sqlite_exec(RXIFRM *frm, void *ctx);
int cmd_sqlite_eval(RXIFRM *frm, void *ctx);
int cmd_sqlite_last_insert_id(RXIFRM *frm, void *ctx);
int cmd_sqlite_finalize(RXIFRM *frm, void *ctx);
int cmd_sqlite_trace(RXIFRM *frm, void *ctx);
int cmd_sqlite_prepare(RXIFRM *frm, void *ctx);
int cmd_sqlite_reset(RXIFRM *frm, void *ctx);
int cmd_sqlite_step(RXIFRM *frm, void *ctx);
int cmd_sqlite_close(RXIFRM *frm, void *ctx);
int cmd_sqlite_columns(RXIFRM *frm, void *ctx);
int cmd_sqlite_initialize(RXIFRM *frm, void *ctx);
int cmd_sqlite_shutdown(RXIFRM *frm, void *ctx);

typedef int (*MyCommandPointer)(RXIFRM *frm, void *ctx);

#define EXT_SQLITE_INIT_CODE \
	"REBOL [Title: \"Rebol SQLite Extension\" Name: sqlite Type: module Exports: [] Version: 3.42.0.1 Author: Oldes Date: 15-Jun-2023/17:54:05+2:00 License: Apache-2.0 Url: https://github.com/Siskin-framework/Rebol-SQLite]\n"\
	"info: command [\"Returns info about SQLite extension library\" /of handle [handle!] \"SQLite Extension handle\"]\n"\
	"open: command [\"Opens a new database connection\" file [file!]]\n"\
	"exec: command [{Runs zero or more semicolon-separate SQL statements} db [handle!] \"sqlite-db\" sql [string!] \"statements\"]\n"\
	"eval: command [\"Evaluates SQL statement with optional paramaters\" db [handle!] \"sqlite-db\" query [string! block! handle!] {single statement, a single statement with parameters or a prepared statement}]\n"\
	"last-insert-id: command [{Returns the rowid of the most recent successful INSERT into a rowid table or virtual table on database connection} db [handle!] \"sqlite-db\"]\n"\
	"finalize: command [\"Deletes prepared statement\" stmt [handle!] \"sqlite-stmt\"]\n"\
	"trace: command [\"Traces debug output\" db [handle!] \"sqlite-db\" mask [integer!]]\n"\
	"prepare: command [\"Prepares SQL statement\" db [handle!] \"sqlite-db\" sql [string!] \"statement\"]\n"\
	"reset: command [\"Resets prepared statement\" stmt [handle!] \"sqlite-stmt\"]\n"\
	"step: command [\"Executes prepared statement\" stmt [handle!] \"sqlite-stmt\" /rows {Multiple times if there is enough rows in the result} count [integer!] /with parameters [block!]]\n"\
	"close: command [\"Closes a database connection\" db [handle!] \"sqlite-db\"]\n"\
	"columns: command [\"Returns column names associated with the statement\" stmt [handle!] \"sqlite-stmt\"]\n"\
	"initialize: command [\"Initializes the SQLite library\"]\n"\
	"shutdown: command [\"Deallocate any resources that were allocated\"]\n"

