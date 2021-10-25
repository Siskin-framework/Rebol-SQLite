//
// Test Rebol extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_open(RXIFRM* frm, void* reb_ctx) {
	REBSER  *filename;
	REBHOB  *hob;
	SQLITE_CONTEXT *ctx;
	sqlite3 *db = NULL;
	int rc;

	RESOLVE_UTF8_STRING(filename, 1);

	hob = RL_MAKE_HANDLE_CONTEXT(Handle_SQLiteDB);
	if (!hob) goto error;
	ctx = (SQLITE_CONTEXT*)hob->data;

	rc = sqlite3_open(SERIES_TEXT(filename), &ctx->db);
	if( rc ) goto error;

	ctx->buf = RL_MAKE_BINARY(1000);

	hob->flags |= HANDLE_CONTEXT; //@@ temp fix!
	RXA_HANDLE(frm, 1) = hob;
	RXA_HANDLE_TYPE(frm, 1) = hob->sym;
	RXA_HANDLE_FLAGS(frm, 1) = hob->flags;
	RXA_TYPE(frm, 1) = RXT_HANDLE;

	return RXR_VALUE;
error:
	if (db) {
		debug_print("Can't open database: %s\n", sqlite3_errmsg(db));
		sqlite3_close(db);
	}
	return RXR_NONE;
}
