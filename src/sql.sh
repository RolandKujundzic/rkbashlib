#!/bin/bash

_SQL=
declare -A _SQL_QUERY
declare -A _SQL_PARAM
declare -A _SQL_COL

#--
# Run _sql[_list|execute|select]. Query is either $2 or _SQL_QUERY[$2] (if set). 
# If $1=select save result of select query to _SQL_COL. Add _SQL_COL[_all] (=STDOUT) and _SQL_COL[_rows].
# If $1=execute ask if query $2 should be execute (default=y) or skip. Set _SQL 
# (default _SQL="rks-db_connect query") and _SQL_QUERY (optional).
#
# BEWARE: don't use `_sql select ...` or $(_sql select) - _SQL_COL will be empty (subshell execution)
#
# @global _SQL _SQL_QUERY (hash) _SQL_PARAM (hash) _SQL_COL (hash)
# @export SQL (=rks-db_connect query)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @require _abort _confirm _sql_echo _sql_execute
# @return boolean (if type=select - false = no result)
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

	test -z "$QUERY" && _abort "empty query in _sql"

	if test "$1" = "select"; then
		_sql_select "$QUERY"
	elif test "$1" = "execute"; then
		_sql_execute "$QUERY" $3
	elif test "$1" = "list"; then
		_sql_list "$QUERY"
	else
		_abort "_sql(...) invalid first parameter [$1] - use select|execute|list"
	fi
}

