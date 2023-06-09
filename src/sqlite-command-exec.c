//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

static int callback(void *NotUsed, int argc, char **argv, char **azColName){
	int i;
	for(i=0; i<argc; i++){
		RL_PRINT(b_cast("%s = %s\n"), azColName[i], argv[i] ? argv[i] : "NULL");
	}
	RL_PRINT(b_cast("\n"),0);
	return 0;
}

int cmd_sqlite_exec(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	REBSER  *sql;
	SQLITE_CONTEXT *ctx;
	sqlite3 *db = NULL;
	int rc;

	RESOLVE_SQLITE_CTX(ctx, 1);
	RESOLVE_UTF8_STRING(sql, 2);

	db = ctx->db;

	//debug_print("exec  DB: %p\n", (void*)db);
	//debug_print("exec SQL: %s\n", SERIES_TEXT(sql));
	rc = sqlite3_exec(db, SERIES_TEXT(sql), callback, 0, 0);
	//debug_print("exec result: %i\n", rc);
	if( rc!=SQLITE_OK ){
		snprintf((char*)error_buffer, 254,"[SQLITE] %s %s", sqlite3_errstr(rc), sqlite3_errmsg(db));
		RXA_SERIES(frm, 1) = (void*)error_buffer;
		return RXR_ERROR;
	}

	return RXR_UNSET;

}
