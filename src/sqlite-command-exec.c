//
// Test Rebol extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

static int callback(void *NotUsed, int argc, char **argv, char **azColName){
	int i;
	for(i=0; i<argc; i++){
		RL_PRINT("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
	}
	RL_PRINT("\n",0);
	return 0;
}

int cmd_sqlite_exec(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	REBSER  *sql;
	SQLITE_CONTEXT *ctx;
	sqlite3 *db = NULL;
	char *zErrMsg = 0;
	int rc;

	RESOLVE_SQLITE_CTX(ctx, 1);
	RESOLVE_UTF8_STRING(sql, 2);

	db = ctx->db;

	//debug_print("exec  DB: %p\n", (void*)db);
	//debug_print("exec SQL: %s\n", SERIES_TEXT(sql));
	rc = sqlite3_exec(db, SERIES_TEXT(sql), callback, 0, &zErrMsg);
	//debug_print("exec result: %i\n", rc);
	if( rc!=SQLITE_OK ){
		fprintf(stderr, "SQL error: %s\n", zErrMsg);
		sqlite3_free(zErrMsg);
	}

	return RXR_UNSET;

}
