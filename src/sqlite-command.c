//
// Rebol/SQLite extension
// ====================================
// Use on your own risc!

#include "sqlite-command.h"

REBSER *utf8_string(RXIARG arg) {
	REBSER *ser = arg.series;
	REBCNT  idx = arg.index;
	return RL_ENCODE_UTF8_STRING(SERIES_SKIP(ser, idx), SERIES_TAIL(ser)-idx, SERIES_WIDE(ser) > 1, FALSE);
}


REBOOL fetch_word(REBSER *cmds, REBCNT index, u32* words, REBCNT *cmd) {
	RXIARG arg;
	REBCNT type = RL_GET_VALUE(cmds, index, &arg);
	//debug_print("fetch_word: %u type: %u\n", index, type);
	return (RXT_WORD == type && (cmd[0] = RL_FIND_WORD(words, arg.int32a)));
}

REBOOL fetch_mode(REBSER *cmds, REBCNT index, REBCNT *result, REBCNT start, REBCNT max) {
	RXIARG arg;
	REBCNT wrd = max;
	REBCNT type = RL_GET_VALUE(cmds, index, &arg);

	if (RXT_WORD == type || RXT_LIT_WORD == type) {
		wrd = RL_FIND_WORD(words_sqlite_arg, arg.int32a) - start;
	} else if (RXT_INTEGER == type) wrd = arg.int64;
	if (wrd >= 0 && wrd < max) {
		result[0] = wrd;
		return TRUE;
	}
	return FALSE;
}

REBOOL fetch_color(REBSER *cmds, REBCNT index, REBCNT *cmd) {
	RXIARG arg;
	REBCNT type = RL_GET_VALUE(cmds, index, &arg);
	//debug_print("fetch_command: %u type: %u\n", index, type);
	if (RXT_WORD == type) {
		cmd[0] = RL_FIND_WORD(words_sqlite_arg, arg.int32a);
		return TRUE;
	}
	return FALSE;
}

