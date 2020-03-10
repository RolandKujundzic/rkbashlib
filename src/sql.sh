#!/bin/bash

_SQL=
declare -A _SQL_QUERY
declare -A _SQL_PARAM
declare -A _SQL_COL

#--
# Run _sql[list|execute|select]. Query is either $2 or _SQL_QUERY[$2] (if set). 
# If $1=select save result of select query to _SQL_COL. Add _SQL_COL[_all] (=STDOUT) and _SQL_COL[_rows].
# If $1=execute ask if query $2 should be execute (default=y) or skip. Set _SQL 
# (default _SQL="rks-db_connect query") and _SQL_QUERY (optional).
# Use _SEARCH_PARAM[SEARCH] to replace WHERE_SEARCH|AND_SEARCH tag.
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

	local ACTION="$1"
	local QUERY="$2"

	if [[ "$1" =~ ^(list|execute|select)_([a-z]+)$ ]]; then
		local ACTION="${BASH_REMATCH[1]}"
		local QUERY="$1"
		test -z "${_SQL_QUERY[$QUERY]}" && _abort "invalid action $ACTION - no such query key $QUERY"
	fi

	if ! test -z "${_SQL_QUERY[$QUERY]}"; then
		QUERY="${_SQL_QUERY[$QUERY]}"
		local a=
	fi

	for a in "${!_SQL_PARAM[@]}"; do
		QUERY="${QUERY//\'$a\'/\'${_SQL_PARAM[$a]}\'}"
	done

	if ! test -z "${_SQL_PARAM[SEARCH]}"; then
		QUERY="${QUERY//WHERE_SEARCH/WHERE 1=1 ${_SQL_PARAM[SEARCH]}}"
		QUERY="${QUERY//AND_SEARCH/${_SQL_PARAM[SEARCH]}}"
	fi

	for a in WHERE_SEARCH AND_SEARCH; do
		QUERY="${QUERY//$a/}"
	done

	test -z "$QUERY" && _abort "empty query in _sql"

	if test "$ACTION" = "select"; then
		_sql_select "$QUERY"
	elif test "$ACTION" = "execute"; then
		_sql_execute "$QUERY" $3
	elif test "$ACTION" = "list"; then
		_sql_list "$QUERY"
	else
		_abort "_sql(...) invalid first parameter [$1] - use select|execute|list or ACTION_QKEY"
	fi
}

