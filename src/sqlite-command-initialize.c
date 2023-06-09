//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_initialize(RXIFRM* frm, void* reb_ctx) {
	int rc  = sqlite3_initialize();
	if (rc != SQLITE_OK) {
		snprintf((char*)error_buffer, 254,"[SQLITE] %s", sqlite3_errstr(rc));
		RXA_SERIES(frm, 1) = (void*)error_buffer;
		return RXR_ERROR;
	}
	return RXR_TRUE;
}
