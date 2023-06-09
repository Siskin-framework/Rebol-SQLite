//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

RL_LIB *RL; // Link back to reb-lib from embedded extensions

//==== Globals ===============================//
u32*   words_sqlite_cmd;
u32*   words_sqlite_arg;
REBCNT Handle_SQLiteDB;
REBCNT Handle_SQLiteSTMT;

REBDEC doubles[DOUBLE_BUFFER_SIZE];
RXIARG arg[ARG_BUFFER_SIZE];

char* error_buffer[255]; // temporary buffer used to pass an exception messages to Rebol side
//============================================//

static const char* init_block = EXT_SQLITE_INIT_CODE;

void* releaseSQLiteDBHandle(void* hndl) {
	SQLITE_CONTEXT *ctx = (SQLITE_CONTEXT*)hndl;
	debug_print("releasing sqlite db: %p\n", ctx->db);
	if(ctx->db) sqlite3_close((sqlite3*)ctx->db);
	return NULL;
}
void* releaseSQLiteSTMTHandle(void* hndl) {
	SQLITE_STMT *ctx = (SQLITE_STMT*)hndl;
	debug_print("releasing sqlite stmt: %p\n", ctx->stmt);
	if(ctx->stmt) sqlite3_finalize((sqlite3_stmt*)ctx->stmt);
	return NULL;
}


RXIEXT const char *RX_Init(int opts, RL_LIB *lib) {
    RL = lib;
	REBYTE ver[8];
	RL_VERSION(ver);
	debug_print("RXinit sqlite-extension; Rebol v%i.%i.%i\n", ver[1], ver[2], ver[3]);

	if (MIN_REBOL_VERSION > VERSION(ver[1], ver[2], ver[3])) {
		debug_print("Needs at least Rebol v%i.%i.%i!\n", MIN_REBOL_VER, MIN_REBOL_REV, MIN_REBOL_UPD);
		return 0;
	}
    if (!CHECK_STRUCT_ALIGN) {
    	trace("CHECK_STRUCT_ALIGN failed!");
    	return 0;
    }
	Handle_SQLiteDB   = RL_REGISTER_HANDLE((REBYTE*)"sqlite-db", sizeof(SQLITE_CONTEXT), releaseSQLiteDBHandle);
	Handle_SQLiteSTMT = RL_REGISTER_HANDLE((REBYTE*)"sqlite-stmt", sizeof(SQLITE_STMT), releaseSQLiteSTMTHandle);
	sqlite3_initialize();
    return init_block;
}


RXIEXT int RX_Call(int cmd, RXIFRM *frm, void *ctx) {
	switch (cmd) {
	case CMD_SQLITE_INFO:    return cmd_sqlite_info(frm, ctx);
	case CMD_SQLITE_OPEN:    return cmd_sqlite_open(frm, ctx);
	case CMD_SQLITE_EXEC:    return cmd_sqlite_exec(frm, ctx);
	case CMD_SQLITE_FINALIZE:return cmd_sqlite_finalize(frm, ctx);
	case CMD_SQLITE_CLOSE:   return cmd_sqlite_close(frm, ctx);
	case CMD_SQLITE_PREPARE: return cmd_sqlite_prepare(frm, ctx);
	case CMD_SQLITE_RESET:   return cmd_sqlite_reset(frm, ctx);
	case CMD_SQLITE_STEP:    return cmd_sqlite_step(frm, ctx);
	case CMD_SQLITE_TRACE:   return cmd_sqlite_trace(frm, ctx);

	case CMD_SQLITE_INITIALIZE: return cmd_sqlite_initialize(frm, ctx);
	case CMD_SQLITE_SHUTDOWN: return cmd_sqlite_shutdown(frm, ctx);

	case CMD_SQLITE_INIT_WORDS:
		words_sqlite_cmd = RL_MAP_WORDS(RXA_SERIES(frm,1));
		words_sqlite_arg = RL_MAP_WORDS(RXA_SERIES(frm,2));
		return RXR_UNSET;
	} // end of commands

	return RXR_ERROR; //@@ FIXME!! This is not correct!
}

RXIEXT int RX_Quit(int opts) {
	debug_print("SQLite extension shutdown.\n", NULL);
	sqlite3_shutdown();
    return 0;
}
