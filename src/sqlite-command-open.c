//
// Rebol/SQLite extension
// ====================================
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

	rc = sqlite3_open(SERIES_TEXT(filename), &ctx->db);
	if(rc != SQLITE_OK) {
		snprintf((char*)error_buffer, 254,"[SQLITE] %s", sqlite3_errstr(rc));
		RXA_SERIES(frm, 1) = (void*)error_buffer;
		return RXR_ERROR;
	}

	RXA_HANDLE(frm, 1) = hob;
	RXA_HANDLE_TYPE(frm, 1) = hob->sym;
	RXA_HANDLE_FLAGS(frm, 1) = hob->flags;
	RXA_TYPE(frm, 1) = RXT_HANDLE;

	return RXR_VALUE;
}
