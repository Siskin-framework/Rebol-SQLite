//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"
#include <inttypes.h>

static double asDouble(uint64_t v) {
    return ((int64_t)(v >> 11)) / (double)(1L << 53);
}

static int trace_callback(unsigned type, void* ctx,void* pStmt,void* pValue){
	uint64_t* duration;

	printf("TRACE[%u] ", type);

	switch(type) {
		case SQLITE_TRACE_STMT:
			printf("STMT: %s\n", sqlite3_expanded_sql((sqlite3_stmt*)pStmt));
			break;
		case SQLITE_TRACE_PROFILE:
			duration = pValue;
			printf("PROFILE: %lluns\n", *duration);
			break;
		case SQLITE_TRACE_ROW:
			puts("ROW");
			break;
		case SQLITE_TRACE_CLOSE:
			puts("CLOSE");
			break;
		default:
			puts("unknown");
			break;
	}
	return SQLITE_OK;
}

int cmd_sqlite_trace(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	SQLITE_CONTEXT *ctx;
	unsigned mask;

	RESOLVE_SQLITE_CTX(ctx, 1);
	if(ctx && ctx->db) {
		mask = RXA_INT64(frm, 2) & 0x0F;
		//printf("mask: %u\n", mask);
		sqlite3_trace_v2(ctx->db, mask, trace_callback, ctx);
	}
	return RXR_UNSET;
}
