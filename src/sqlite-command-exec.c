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

static int callback(void *NotUsed, int argc, char **argv, char **azColName){
	int i;
	for(i=0; i<argc; i++){
		RL_PRINT(b_cast("%s = %s\n"), azColName[i], argv[i] ? argv[i] : "NULL");
	}
	RL_PRINT(b_cast("\n"),0);
	return 0;
}

//static int eval_row_callback(void *arg, int argc, char **argv, char **azColName){
//	int i;
//	char *str;
//	REBSER  *row;
//	REBSER  *blk = (REBSER*)arg;
//	RXIARG   arg = {0};
//
//	arg.series = row = RL_MAKE_BLOCK(2 * argc);
//	RL_SET_VALUE(blk, SERIES_TAIL(blk), arg, RXT_BLOCK);
//
//	for(i=0; i<argc; i++){
//		str = azColName[i];
//		arg.series = RL_DECODE_UTF_STRING((REBYTE*)str, strlen(str), 8, 0, 0);
//		RL_SET_VALUE(row, SERIES_TAIL(row), arg, RXT_STRING);
//
//		str = argv[i] ? argv[i] : "none";
//		arg.series = RL_DECODE_UTF_STRING((REBYTE*)str, strlen(str), 8, 0, 0);
//		RL_SET_VALUE(row, SERIES_TAIL(row), arg, RXT_STRING);
//	}
//	return 0;
//}

int cmd_sqlite_exec(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	REBSER  *sql;
	SQLITE_CONTEXT *ctx;
	sqlite3 *db = NULL;
	int rc;

	RESOLVE_SQLITE_CTX(ctx, 1);
	sql = utf8_string(RXA_ARG(frm, 2));

	db = ctx->db;

	//debug_print("exec  DB: %p\n", (void*)db);
	//debug_print("exec SQL: %s\n", SERIES_TEXT(sql));
	rc = sqlite3_exec(db, SERIES_TEXT(sql), callback, 0, 0);

// Code to collect callback args instead of printing it directly...
//	REBSER *result = RL_MAKE_BLOCK(4);
//	RXA_SERIES(frm, 1) = result;
//	RXA_TYPE  (frm, 1) = RXT_BLOCK;
//	RXA_INDEX (frm, 1) = 0;
//
//	rc = sqlite3_exec(db, SERIES_TEXT(sql), eval_row_callback, result, 0);
//	if( rc == SQLITE_OK ) return RXR_VALUE;


	//debug_print("exec result: %i\n", rc);
	if( rc!=SQLITE_OK ){
		snprintf((char*)error_buffer, 254,"[SQLITE] %s %s", sqlite3_errstr(rc), sqlite3_errmsg(db));
		RXA_SERIES(frm, 1) = (void*)error_buffer;
		return RXR_ERROR;
	}

	return RXR_UNSET;

}
