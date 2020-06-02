#!/bin/bash

#--
# Run sql execute query (no result).
#
# @param sql query
# @param flag (1=execute sql without confirmation)
# @global SQL
#--
function _sql_execute {
	local query="$1"
	test -z "$query" && _abort "empty sql execute query"
	_require_global SQL

	if test "$2" = "1"; then
		echo "execute sql query: $(_sql_echo "$query")"
		$SQL "$query" || _abort "$query"
	else
		_confirm "execute sql query: $(_sql_echo "$query")? " 1
		test "$CONFIRM" = "y" && { $SQL "$query" || _abort "$query"; }
	fi
}

