//
// Test Rebol extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_finalize(RXIFRM* frm, void* reb_ctx) {
	REBHOB      *hobStmt;
	SQLITE_STMT *ctxStmt;

	RESOLVE_SQLITE_STMT(ctxStmt, 1);
	sqlite3_finalize(ctxStmt->stmt);
	ctxStmt->stmt = NULL;
	return RXR_UNSET;
}
