#!/bin/bash

_SQL=
declare -A _SQL_QUERY
declare -A _SQL_PARAM

#--
# Run sql select or execute query. Query is either $2 or _SQL_QUERY[$2] (if set). 
# If $1=select print result of select query. If $1=execute ask if query $2 should
# be execute (default=y) or skip. Set _SQL (default _SQL="rks-db_connect query") and
# _SQL_QUERY (optional).
#
# @global _SQL _SQL_QUERY (hash) _SQL_PARAM (hash)
# @export SQL (=rks-db_connect query)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @require _abort _confirm
#--
function _sql {
	if test -z "$_SQL"; then
		if test -s "/usr/local/bin/rks-db_connect"; then
			_SQL='rks-db_connect query'
		else
			_abort "set _SQL="
		fi
	fi

	local QUERY="$2"
	if ! test -z "${_SQL_QUERY[$2]}"; then
		QUERY="${_SQL_QUERY[$2]}"
		local a=

		for a in "${!_SQL_PARAM[@]}"; do
			QUERY="${QUERY//\'$a\'/\'${_SQL_PARAM[$a]}\'}"
		done
	fi

	test -z "$QUERY" && _abort "empty query in _sql $1"

	if test "$1" = "select"; then
		$_SQL "$QUERY" | tail -1
	elif test "$1" = "execute"; then
		if test "$3" = "1"; then
			echo "execute sql query: ${QUERY:0:20} ..."
			$_SQL "$QUERY"
		else
			_confirm "execute sql query: ${QUERY:0:20} ... ? " 1
			test "$CONFIRM" = "y" && $_SQL "$QUERY"
		fi
	else
		_abort "_sql(...) invalid first parameter [$1] - use select|execute"
	fi
}

