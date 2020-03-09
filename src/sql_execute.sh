#!/bin/bash

#--
# Run sql execute query (no result).
#
# @param sql query
# @param flag (1=execute sql without confirmation)
# @global _SQL
# @require _abort _confirm _sql_echo _require_global
#--
function _sql_execute {
	local QUERY="$1"
	test -z "$QUERY" && _abort "empty sql execute query"
	_require_global "_SQL"
	if test "$2" = "1"; then
		echo "execute sql query: $(_sql_echo "$QUERY")"
		$_SQL "$QUERY" || _abort "$QUERY"
	else
		_confirm "execute sql query: $(_sql_echo "$QUERY")? " 1
		test "$CONFIRM" = "y" && { $_SQL "$QUERY" || _abort "$QUERY"; }
	fi
}

