//
// Test Rebol extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_prepare(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	REBHOB  *hobStmt;
	REBSER  *sql;
	SQLITE_CONTEXT *ctx;
	SQLITE_STMT *ctxStmt;
	sqlite3 *db = NULL;
	char *zErrMsg = 0;
	const char *zTail = 0;
	int rc;

	RESOLVE_SQLITE_CTX(ctx, 1);
	sql = RXA_SERIES(frm, 2);

	db = ctx->db;

	//debug_print("prep  DB: %p\n", (void*)db);
	//debug_print("prep SQL: %s\n", SERIES_TEXT(sql));

	hobStmt = RL_MAKE_HANDLE_CONTEXT(Handle_SQLiteSTMT);
	ctxStmt = (SQLITE_STMT*)hobStmt->data;

	rc = sqlite3_prepare_v2(db, SERIES_TEXT(sql), SERIES_TAIL(sql), &ctxStmt->stmt, &zTail);

	//debug_print("prep result: %i\n", rc);
	//debug_print("tail: %s\n", zTail);
	if( rc!=SQLITE_OK ){
		fprintf(stderr, "SQL error: %s\n", zErrMsg);
		sqlite3_free(zErrMsg);
		return RXR_NONE;
	}

	hobStmt->flags |= HANDLE_CONTEXT; //@@ temp fix!
	RXA_HANDLE(frm, 1) = hobStmt;
	RXA_HANDLE_TYPE(frm, 1) = hobStmt->sym;
	RXA_HANDLE_FLAGS(frm, 1) = hobStmt->flags;

	return RXR_VALUE;
}
