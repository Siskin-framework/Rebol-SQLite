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

int cmd_sqlite_finalize(RXIFRM* frm, void* reb_ctx) {
	REBHOB      *hobStmt;
	SQLITE_STMT *ctxStmt;

	RESOLVE_SQLITE_STMT(ctxStmt, 1);
	sqlite3_finalize(ctxStmt->stmt);
	ctxStmt->stmt = NULL;
	return RXR_UNSET;
}
