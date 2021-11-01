// auto-generated file, do not modify! //

#include "sqlite-command.h"

#define MIN_REBOL_VER 3
#define MIN_REBOL_REV 5
#define MIN_REBOL_UPD 4
#define VERSION(a, b, c) (a << 16) + (b << 8) + c
#define MIN_REBOL_VERSION VERSION(MIN_REBOL_VER, MIN_REBOL_REV, MIN_REBOL_UPD)

extern REBCNT Handle_SQLiteDB;
extern REBCNT Handle_SQLiteSTMT;

enum sqlite_commands {
	CMD_SQLITE_INIT_WORDS,
	CMD_SQLITE_INFO,
	CMD_SQLITE_OPEN,
	CMD_SQLITE_EXEC,
	CMD_SQLITE_FINALIZE,
	CMD_SQLITE_TRACE,
	CMD_SQLITE_PREPARE,
	CMD_SQLITE_RESET,
	CMD_SQLITE_STEP,
	CMD_SQLITE_CLOSE,
	CMD_SQLITE_INITIALIZE,
	CMD_SQLITE_SHUTDOWN,
};
enum words_sqlite_cmd {W_SQLITE_CMD_0,
};
enum words_sqlite_arg {W_SQLITE_ARG_0,
};

int cmd_sqlite_init_words(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_info(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_open(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_exec(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_finalize(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_trace(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_prepare(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_reset(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_step(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_close(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_initialize(RXIFRM* frm, void* reb_ctx);
int cmd_sqlite_shutdown(RXIFRM* frm, void* reb_ctx);

#define EXT_SQLITE_INIT_CODE \
	"REBOL [Title: {Rebol SQLite Extension} Type: module Exports: []]\n"\
	"init-words: command [cmd-words [block!] arg-words [block!]]\n"\
	"info: command [\"Returns info about SQLite extension library\" /of handle [handle!] \"SQLite Extension handle\"]\n"\
	"open: command [\"Open a new database connection\" file [file!]]\n"\
	"exec: command [\"Run zero or more semicolon-separate SQL statements\" db [handle!] \"sqlite-db\" sql [string!] \"statements\"]\n"\
	"finalize: command [\"Delete prepared statement\" stmt [handle!] \"sqlite-stmt\"]\n"\
	"trace: command [\"Trace debug output\" db [handle!] \"sqlite-db\" mask [integer!]]\n"\
	"prepare: command [\"Prepare SQL statement\" db [handle!] \"sqlite-db\" sql [string!] \"statement\"]\n"\
	"reset: command [\"Reset prepared statement\" stmt [handle!] \"sqlite-stmt\"]\n"\
	"step: command [\"Execute prepared statement\" stmt [handle!] \"sqlite-stmt\" /rows {Multiple times if there is enough rows in the result} count [integer!] /with parameters [block!]]\n"\
	"close: command [\"Close database connection\" db [handle!] \"sqlite-db\"]\n"\
	"initialize: command [\"Initializes the SQLite library\"]\n"\
	"shutdown: command [\"Deallocate any resources that were allocated\"]\n"\
	"init-words words: [] []\n"\
	"protect/hide 'init-words\n"\
