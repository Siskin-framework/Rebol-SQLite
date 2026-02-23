//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include "sqlite3.h"
#include "sqlite-vec.h"
#include "rebol-extension.h"

#define SERIES_TEXT(s)   ((char*)SERIES_DATA(s))

//#define USE_TRACES
#ifdef  USE_TRACES
//#include <stdio.h>
#define debug_print(fmt, ...) do { printf(fmt, __VA_ARGS__); } while (0)
#define trace(str) puts(str)
#else
#define debug_print(fmt, ...)
#define trace(str) 
#endif

#define DOUBLE_BUFFER_SIZE 16
#define ARG_BUFFER_SIZE    8


typedef struct reb_sqlite_context {
	sqlite3* db;
	REBSER* buf;
	int id;
	int last_insert_count;
} SQLITE_CONTEXT;

typedef struct reb_sqlite_stmt {
	sqlite3_stmt* stmt;
	int last_result_code;
} SQLITE_STMT;


REBSER* utf8_string(RXIARG arg);
REBOOL fetch_word (REBSER *cmds, REBCNT index, u32* words, REBCNT *cmd);
REBOOL fetch_mode (REBSER *cmds, REBCNT index, REBCNT *result, REBCNT start, REBCNT max);
REBOOL fetch_color(REBSER *cmds, REBCNT index, REBCNT *cmd);

void* releaseTestExtensionCtx(void* ctx);
void* releaseSQLiteSTMTHandle(void* hndl);


extern u32* words_sqlite_cmd;
extern u32* words_sqlite_arg;


extern REBDEC doubles[DOUBLE_BUFFER_SIZE];
extern RXIARG arg[ARG_BUFFER_SIZE];


//==============================================================//
// Some useful defines                                          //
//==============================================================//



#define RETURN_STR_ERROR(str) do {RXA_SERIES(frm, 1) = str; return RXR_ERROR;} while(0);


#define RESOLVE_UTF8_STRING(n, i) \
	n   = RXA_SERIES(frm, i);     \
	idx = RXA_INDEX(frm, i);      \
	n = RL_ENCODE_UTF8_STRING(SERIES_SKIP(n, idx), SERIES_TAIL(n)-idx, SERIES_WIDE(n) > 1, FALSE);

#define RESOLVE_SQLITE_CTX(n, i)                     \
			hob = RXA_HANDLE(frm, i);               \
			n = (SQLITE_CONTEXT*)hob->data;         \
			if(!n || hob->sym != Handle_SQLiteDB )  \
				RETURN_STR_ERROR("Invalid SQLite DB handle!");

#define RESOLVE_SQLITE_STMT(n, i)                   \
			hobStmt = RXA_HANDLE(frm, i);           \
			n = (SQLITE_STMT*)hobStmt->data;        \
			if(!n || hobStmt->sym != Handle_SQLiteSTMT || !(n)->stmt) \
				RETURN_STR_ERROR("Invalid SQLite STMT handle!");

