//
// Test Rebol extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_close(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	SQLITE_CONTEXT *ctx;

	RESOLVE_SQLITE_CTX(ctx, 1);
	if(ctx && ctx->db) {
		sqlite3_close(ctx->db);
		ctx->db = NULL;
	}
	return RXR_UNSET;
}
