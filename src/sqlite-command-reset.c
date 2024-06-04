//   ____  __   __        ______        __
//  / __ \/ /__/ /__ ___ /_  __/__ ____/ /
// / /_/ / / _  / -_|_-<_ / / / -_) __/ _ \
// \____/_/\_,_/\__/___(@)_/  \__/\__/_// /
//  ~~~ oldes.huhuman at gmail.com ~~~ /_/
//
// SPDX-License-Identifier: MIT
// =============================================================================
// Rebol/SQLite extension
// =============================================================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_reset(RXIFRM* frm, void* reb_ctx) {
	REBHOB      *hobStmt;
	SQLITE_STMT *ctxStmt;

	RESOLVE_SQLITE_STMT(ctxStmt, 1);
	sqlite3_reset(ctxStmt->stmt);
	ctxStmt->last_result_code = SQLITE_ROW;
	
	return RXR_UNSET;
}
