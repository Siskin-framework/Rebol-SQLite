//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"

int cmd_sqlite_step(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hobStmt;
	REBSER  *ser;
	REBSER  *str;
	REBSER  *blk = NULL;
	REBYTE  *bin;
	RXIARG   arg = {0};
	SQLITE_STMT *ctxStmt;
	sqlite3_stmt *stmt;
	char *zErrMsg = 0;
	int rc, columns, bytes, row, col, type;
	int refRows, allRows = 0;
	i64 maxRows, rows;

	RESOLVE_SQLITE_STMT(ctxStmt, 1);
	refRows = RXA_REF(frm, 2);
	maxRows = RXA_INT64(frm, 3);
	if (!refRows) maxRows = 1;
	if (maxRows < 1) allRows = maxRows = 1;
	rows = (maxRows > 1000) ? 1000 : maxRows; //no need to use exact pow2 numbers, Rebol will do it anyway

	stmt = ctxStmt->stmt;

	if (RXA_REF(frm, 4)) { // with
		ser = RXA_SERIES(frm, 5);

		//sqlite3_reset() does not reset the bindings on a prepared statement!
		sqlite3_clear_bindings(stmt);
		
		for(col = 0; col < SERIES_TAIL(ser); col++) {
			type = RL_GET_VALUE(ser, col, &arg);
			//printf("arg type: %i\n", type);
			rc = -1;
			switch(type) {
				case RXT_INTEGER:
					rc = sqlite3_bind_int64(stmt, col+1, arg.int64);
					break;
				case RXT_DECIMAL:
					rc = sqlite3_bind_double(stmt, col+1, arg.dec64);
					break;
				case RXT_STRING:
					// Make sure to convert unicode string to UTF-8
					str = (REBSER*)arg.series;
					if (SERIES_WIDE(str) > 1) {
						str = RL_ENCODE_UTF8_STRING(SERIES_DATA(str), SERIES_TAIL(str), TRUE, FALSE);
					}
					rc = sqlite3_bind_text(stmt, col+1, SERIES_TEXT(str), -1, SQLITE_TRANSIENT);
					break;
				case RXT_NONE:
					rc = sqlite3_bind_null(stmt, col+1);
					break;
				case RXT_LOGIC:
					rc = sqlite3_bind_int(stmt, col+1, arg.int32a);
					break;
			}
			//debug_print("bind result: %i\n", rc);
		}
	}

	rc = sqlite3_stmt_readonly(stmt) ? ctxStmt->last_result_code : SQLITE_ROW;

	for (row = 0; rc == SQLITE_ROW && (allRows || row < maxRows); row++) {
		rc = sqlite3_step(stmt);
		ctxStmt->last_result_code = rc;
		//debug_print("row: %i = step result: %i, requested rows: %li allRows: %i\n", row, rc, maxRows, allRows);
		switch(rc) {
			case SQLITE_ROW:
				if (!blk) {
					columns = sqlite3_data_count(stmt);
					//debug_print("step has data: %i columns\n", columns);

					// preallocate the block to hold results...
					blk = RL_MAKE_BLOCK(columns * rows);
					RXA_SERIES(frm, 1) = blk;
					RXA_TYPE  (frm, 1) = RXT_BLOCK;
					RXA_INDEX (frm, 1) = 0;
				}

				//debug_print("SERIES_TAIL(s) = %u SERIES_REST(s) = %u\n", SERIES_TAIL(blk), SERIES_REST(blk));

				CLEARS(&arg);
				for(col = 0; col < columns; col++) {
					type = sqlite3_column_type(stmt, col);
					//debug_print("column[%ix%i] type: %i\n", row, col, type);
					switch(type) {
						case SQLITE_INTEGER:
							type = RXT_INTEGER;
							arg.int64 = sqlite3_column_int64(stmt, col);
							break;
						case SQLITE_FLOAT:
							type = RXT_DECIMAL;
							arg.dec64 = sqlite3_column_double(stmt, col);
							break;
						case SQLITE_TEXT:
							type = RXT_STRING;
							bytes = sqlite3_column_bytes(stmt, col);
							arg.series = RL_DECODE_UTF_STRING((REBYTE*)sqlite3_column_text(stmt, col), bytes, 8, 0, 0);
							break;
						case SQLITE_BLOB:
							type = RXT_BINARY;
							bytes = sqlite3_column_bytes(stmt, col);
							bin = (REBYTE*)sqlite3_column_blob(stmt, col);
							if (bin) {
								ser = RL_MAKE_BINARY(bytes);
								memcpy(SERIES_DATA(ser), bin, bytes);
								SERIES_TAIL(ser) = bytes;
								arg.series = ser;
							}
							break;
						case SQLITE_NULL:
							type = RXT_NONE;
					}
					// Append the new column value into the result.
					// It also expands the series if there is no room and updates its tail.
					RL_SET_VALUE(blk, (row * columns) + col, arg, type);
				}
				break;
			case SQLITE_DONE:
				//trace("step done");
				if(blk) return RXR_VALUE;
				sqlite3_reset(stmt);
				return RXR_NONE;
			case SQLITE_BUSY:
				//trace("step busy");
				RXA_SERIES(frm, 1) = "[SQLITE] Statement is busy!";
				return RXR_ERROR;
			case SQLITE_ERROR:
				rc = sqlite3_reset(stmt);
				RXA_SERIES(frm, 1) = (void*)sqlite3_errstr(rc);
				//debug_print("step error: %s\n", sqlite3_errstr(rc));
				return RXR_ERROR;
			case SQLITE_MISUSE:
				//trace("step misuse");
				RXA_SERIES(frm, 1) = "[SQLITE] Statement misuse!";
				return RXR_ERROR;
		}
	}
	if(blk) return RXR_VALUE;
	return RXR_NONE;
}
