//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_columns(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hobStmt;
	REBSER  *blk = NULL;
	REBINT   count, i;
	RXIARG   arg = {0};
	SQLITE_STMT *ctxStmt;
	const char *name;

	RESOLVE_SQLITE_STMT(ctxStmt, 1);

	count = sqlite3_column_count(ctxStmt->stmt);

	debug_print("column_count: %i\n", count);
	if (count == 0) return RXR_NONE;
	blk = RL_MAKE_BLOCK(count);
	for (i = 0; i < count; i++) {
		name = sqlite3_column_name(ctxStmt->stmt, i);
		// It is not possible to return names as words, because RL_MAP_WORD
		// is able to create invalid words (containing invalid characters)
		// That is possible with queries like: SELECT randomblob(16);

		REBCNT sym = RL_MAP_WORD(name);
		//debug_print("column_name: %s %u\n", name, sym);
		//arg.int32a = sym; // Used with RL_SET_VALUE...RXT_WORD
		
		// So just return names as strings...
		arg.series = RL_DECODE_UTF_STRING((REBYTE*)name, strlen(name), 8, 0, 0);
		RL_SET_VALUE(blk, SERIES_TAIL(blk), arg, RXT_STRING);
	}

	RXA_SERIES(frm, 1) = blk;
	RXA_TYPE  (frm, 1) = RXT_BLOCK;
	RXA_INDEX (frm, 1) = 0;
	return RXR_VALUE;
}
