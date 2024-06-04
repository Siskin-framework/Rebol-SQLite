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


int cmd_sqlite_info(RXIFRM* frm, void* reb_ctx) {
	// return library info...
	REBI64  tail = 0;
	REBSER *str  = RL_MAKE_STRING(1000, FALSE); // 1024 bytes, latin1 (must be large enough!)
	REBYTE rebol_version[8];


	if (RXT_HANDLE == RXA_TYPE(frm, 2)) {
		// Info about given handle...
		REBHOB* hob = RXA_HANDLE(frm, 2);
		//debug_print("hob: %p\n", hob);

		if (hob->sym == Handle_SQLiteDB) {
			SQLITE_CONTEXT* ctx = (SQLITE_CONTEXT*)hob->data;
			//debug_print("ctx: %p\n", ctx);
			if(!ctx) return RXR_NONE;
			tail = snprintf(
				SERIES_TEXT(str),
				SERIES_REST(str),
				"sqlite-ctx-Ptr: <%p>\n"
				"sqlite-ctx-DB:  <%p>\n"
				"sqlite-buffer-size: %i\n",
				(void*)ctx,
				ctx->db,
				(ctx->buf ? SERIES_REST(ctx->buf) : 0)
			);
		}
		else if (hob->sym == Handle_SQLiteSTMT) {
			SQLITE_STMT* ctx = (SQLITE_STMT*)hob->data;
			//debug_print("ctx: %p\n", ctx);
			if(!ctx) return RXR_NONE;
			tail = snprintf(
				SERIES_TEXT(str),
				SERIES_REST(str),
				"sqlite-stmt-Ptr:  <%p>\n"
				"sqlite-stmt:      <%p>\n"
				"last-result-code:  %i\n"
				"bind-parameters:   %i\n"
				"data-count:        %i\n",
				(void*)ctx,
				ctx->stmt,
				ctx->last_result_code,
				(ctx->stmt ? sqlite3_bind_parameter_count(ctx->stmt) : 0),
				sqlite3_data_count(ctx->stmt)
			);
		}
		else {
			// unsupported handle
		}
	}
	else {
		// Some system info...
		RL_VERSION(rebol_version);

		tail = snprintf(
			SERIES_TEXT(str),
			SERIES_REST(str),
			"\n"
			"Rebol-needed:   %u.%u.%u\n"
			"Rebol-current:  %u.%u.%u\n"
			"SQLite-version: %s\n"
			"SQLite-memory:  %llu\n" // the number of bytes of memory currently outstanding (malloced but not freed)
			"SQLite-mem-top: %llu\n",
			MIN_REBOL_VER, MIN_REBOL_REV, MIN_REBOL_UPD,
			rebol_version[1], rebol_version[2], rebol_version[3],
			sqlite3_libversion(),
			sqlite3_memory_used(),
			sqlite3_memory_highwater(0)
		);
	}
	if (tail < 0) return RXR_NONE;
	else {
		SERIES_TAIL(str) = tail;
		RXA_SERIES(frm, 1) = str;
		RXA_TYPE(frm, 1) = RXT_STRING;
		RXA_INDEX(frm, 1) = 0;
	}
	return RXR_VALUE;
}
