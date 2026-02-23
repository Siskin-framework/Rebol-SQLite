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

int cmd_sqlite_open(RXIFRM* frm, void* reb_ctx) {
	REBSER  *filename;
	REBHOB  *hob;
	SQLITE_CONTEXT *ctx;
	int rc;

	filename = utf8_string(RXA_ARG(frm, 1));

	hob = RL_MAKE_HANDLE_CONTEXT(Handle_SQLiteDB);
	if (!hob) {
		RXA_SERIES(frm, 1) = "[SQLITE] Failed to allocate a handle!";
		return RXR_ERROR;
	}
	ctx = (SQLITE_CONTEXT*)hob->data;

	// Initialize embedded sqlite-vec extension.
	// (Maybe it should be done on the request only...)
	rc = sqlite3_auto_extension((void(*)(void))sqlite3_vec_init);
	if(rc != SQLITE_OK) goto error;

	rc = sqlite3_open(SERIES_TEXT(filename), &ctx->db);
	if(rc != SQLITE_OK) goto error;

	RXA_HANDLE(frm, 1) = hob;
	RXA_HANDLE_TYPE(frm, 1) = hob->sym;
	RXA_HANDLE_FLAGS(frm, 1) = hob->flags;
	RXA_TYPE(frm, 1) = RXT_HANDLE;

	return RXR_VALUE;

error:
	snprintf((char*)error_buffer, 254,"[SQLITE] %s", sqlite3_errstr(rc));
	RXA_SERIES(frm, 1) = (void*)error_buffer;
	return RXR_ERROR;

}
