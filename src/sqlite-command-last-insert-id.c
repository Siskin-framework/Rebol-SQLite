//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_last_insert_id(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	SQLITE_CONTEXT *ctx;

	RESOLVE_SQLITE_CTX(ctx, 1);

	RXA_INT64(frm, 1) = sqlite3_last_insert_rowid(ctx->db);
	RXA_TYPE (frm, 1) = RXT_INTEGER;
	return RXR_VALUE;
}