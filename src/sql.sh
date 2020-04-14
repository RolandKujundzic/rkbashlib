#!/bin/bash

_SQL=
declare -A _SQL_QUERY

#--
# Run _sql[list|execute|select]. Query is either $2 or _SQL_QUERY[$2] (if set). 
# If $1=execute ask if query $2 should be execute (default=y) or skip. 
# Set _SQL (default _SQL="rks-db query") and _SQL_QUERY (optional).
# See _sql_querystring for parameter and search parameter replace.
# See _sql_select for _SQL_COL results.
#
# BEWARE: don't use `_sql select ...` or $(_sql select) - _SQL_COL will be empty (subshell execution)
#
# @global _SQL _SQL_QUERY (hash)
# @export SQL (=rks-db query)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @require _abort _confirm _sql_select _sql_execute _sql_list _sql_querystring
# @return boolean (if type=select - false = no result)
#--
function _sql {
	if test -z "$_SQL"; then
		if test -s "/usr/local/bin/rks-db"; then
			_SQL='rks-db query'
		else
			_abort "set _SQL="
		fi
	fi

	local ACTION="$1"
	local QUERY="$2"

	if [[ "$1" =~ ^(list|execute|select)_([a-z]+)$ ]]; then
		ACTION="${BASH_REMATCH[1]}"
		QUERY="$1"
		test -z "${_SQL_QUERY[$QUERY]}" && _abort "invalid action $ACTION - no such query key $QUERY"
	fi

	test -z "${_SQL_QUERY[$QUERY]}" || QUERY="${_SQL_QUERY[$QUERY]}"

	QUERY=`_sql_querystring "$QUERY"`

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

