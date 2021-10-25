//
// Test Rebol extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_reset(RXIFRM* frm, void* reb_ctx) {
	REBHOB      *hobStmt;
	SQLITE_STMT *ctxStmt;

	RESOLVE_SQLITE_STMT(ctxStmt, 1);
	sqlite3_reset(ctxStmt->stmt);
	return RXR_UNSET;
}
