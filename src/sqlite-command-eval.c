//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-rebol-extension.h"


int bind_parameters(sqlite3_stmt *stmt, REBSER *params, REBCNT *index) {
	REBINT count, col, rc, type ;
	RXIARG   arg = {0};
	REBSER  *str;
	REBCNT   idx = *index;
	REBOOL   blockData = FALSE;

	rc = 0;

	// bind statement's parameters...
	if (params && stmt) {

		type = RL_GET_VALUE_RESOLVED(params, idx, &arg);
		if (type == RXT_BLOCK) {
			//trace("block params");
			params = arg.series;
			idx = arg.index;
			blockData = TRUE;		
		}
		//trace("bind");
		//sqlite3_reset(stmt);
		count = sqlite3_bind_parameter_count(stmt);
		if (count) sqlite3_clear_bindings(stmt);

		//debug_print("binding %i parameters... index: %u\n", count, idx);

		for(col = 0; col < count; idx++) {
			col++;
			type = RL_GET_VALUE_RESOLVED(params, idx, &arg);
			rc = SQLITE_MISUSE;
			switch(type) {
			case RXT_INTEGER:
				rc = sqlite3_bind_int64(stmt, col, arg.int64);
				break;
			case RXT_DECIMAL:
				rc = sqlite3_bind_double(stmt, col, arg.dec64);
				break;
			case RXT_STRING:
				// Make sure to convert unicode string to UTF-8
				str = (REBSER*)arg.series;
				if (SERIES_WIDE(str) > 1) {
					str = RL_ENCODE_UTF8_STRING(SERIES_DATA(str), SERIES_TAIL(str), TRUE, FALSE);
				}
				rc = sqlite3_bind_text(stmt, col, SERIES_TEXT(str), -1, SQLITE_TRANSIENT);
				break;
			case RXT_NONE:
				rc = sqlite3_bind_null(stmt, col);
				break;
			case RXT_LOGIC:
				rc = sqlite3_bind_int(stmt, col, arg.int32a);
				break;
			case RXT_END:
				rc = SQLITE_OK;
				break;
			}
		}
	}
	//debug_print("bind rc: %i\n", rc);
	*index = blockData ? *index+1 : idx;
	return rc;
}

int cmd_sqlite_eval(RXIFRM* frm, void* reb_ctx) {
	REBHOB  *hob;
	REBHOB  *hobStmt;
	REBSER  *sql;
	REBCNT   index;
	REBCNT   row, maxRows;
	REBINT   type, col, columns, bytes, count;
	
	REBSER  *ser;
	REBSER  *str;
	REBSER  *params = NULL;
	REBSER  *result = NULL;
	REBYTE  *bin;
	RXIARG   arg = {0};
	REBOOL   freeStmt = FALSE;

	SQLITE_STMT    *ctxStmt = NULL;
	SQLITE_CONTEXT *ctx;
	sqlite3        *db   = NULL;
	sqlite3_stmt   *stmt = NULL;
	int rc;
	int ret = RXR_UNSET;

	maxRows = (REBCNT)-1; //TODO: it should be user defined

	RESOLVE_SQLITE_CTX(ctx, 1);
	db = ctx->db;

	ctx->last_insert_count = 0;

	if (RXA_TYPE(frm,2) == RXT_HANDLE) {
		RESOLVE_SQLITE_STMT(ctxStmt, 2);
		stmt = ctxStmt->stmt;
	}
	else if (RXA_TYPE(frm,2) == RXT_STRING) {
		// evaluate single or more semicolon separated statemens using the sqlite_exec function
		sql = utf8_string(RXA_ARG(frm, 2));
		rc = sqlite3_prepare_v2(db, SERIES_TEXT(sql), SERIES_TAIL(sql), &stmt, 0);
		if( rc!=SQLITE_OK ) goto error;
		freeStmt = TRUE;
		//debug_print("SQL: %s\n", SERIES_TEXT(sql));
	}
	else if (RXA_TYPE(frm,2) == RXT_BLOCK) {
		params = RXA_SERIES(frm, 2);
		index  = RXA_INDEX(frm, 2);
		type = RL_GET_VALUE_RESOLVED(params, index, &arg);
		if (type == RXT_STRING) {
			sql = utf8_string(arg);
			rc = sqlite3_prepare_v2(db, SERIES_TEXT(sql), SERIES_TAIL(sql), &stmt, 0);
			if( rc!=SQLITE_OK ) goto error;
			freeStmt = TRUE;
		}
		else if (type == RXT_HANDLE) {
			hobStmt = arg.handle.ptr;
			if (hobStmt->sym != Handle_SQLiteSTMT) {
				rc = SQLITE_MISUSE;
				goto error;
			}
			ctxStmt = (SQLITE_STMT*)hobStmt->data;
			stmt = ctxStmt->stmt;
		}
		else {
			rc = SQLITE_MISUSE;
			goto error;
		}
		index++;
	}

	// bind statement's parameters...
	if (params) {
		//if (ctxStmt) debug_print("ctxStmt->last_result_code = %i\n", ctxStmt->last_result_code);
		if (ctxStmt && ctxStmt->last_result_code == SQLITE_DONE) sqlite3_reset(stmt);
		rc = bind_parameters(stmt, params, &index);
		if (rc != SQLITE_OK) goto finish;
	}

	// evaluate single statement using the sqlite_step function
	for (row = 0; row < maxRows; row++) {
		rc = sqlite3_step(stmt);
		if (ctxStmt) ctxStmt->last_result_code = rc;
		//debug_print("row: %i = step result: %i, requested rows: %u\n", row, rc, maxRows);

		switch(rc) {
			case SQLITE_ROW:
				if (!result) {
					columns = sqlite3_data_count(stmt);
					//debug_print("step has data: %i columns\n", columns);

					// preallocate the block to hold results...
					result = RL_MAKE_BLOCK(columns);
					RXA_SERIES(frm, 1) = result;
					RXA_TYPE  (frm, 1) = RXT_BLOCK;
					RXA_INDEX (frm, 1) = 0;
				}

				//debug_print("SERIES_TAIL(s) = %u SERIES_REST(s) = %u\n", SERIES_TAIL(result), SERIES_REST(result));

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
					RL_SET_VALUE(result, (row * columns) + col, arg, type);
				}
				break;
			case SQLITE_DONE:
				//trace("step done");
				if(result) return RXR_VALUE;
				ctx->last_insert_count += sqlite3_changes(db);
				sqlite3_reset(stmt);

				if (params && index < SERIES_TAIL(params)) {
					//debug_print("bind_parameters index: %i\n", index);
					rc = bind_parameters(stmt, params, &index);
					if (rc != SQLITE_OK) goto finish;
					continue;
				}
				if (freeStmt) sqlite3_finalize(stmt);
				RXA_INT64(frm, 1) = ctx->last_insert_count;
				RXA_TYPE (frm, 1) = RXT_INTEGER;
				
				return RXR_VALUE;

			default:
				//rc = sqlite3_reset(stmt);
				goto finish;
		}
	}

	
finish:
	if (freeStmt) sqlite3_finalize(stmt);
	if( rc!=SQLITE_OK ){
error:
		snprintf((char*)error_buffer, 254,"[SQLITE] %s", sqlite3_errstr(rc));
		RXA_SERIES(frm, 1) = (void*)error_buffer;
		return RXR_ERROR;
	}

	return ret;
}
