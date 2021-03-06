#!/bin/bash

SQL=
declare -A SQL_QUERY

#--
# Run _sql[list|execute|select]. Query is either $2 or SQL_QUERY[$2] (if set). 
# If $1=execute ask if query $2 should be execute (default=y) or skip. 
# Set SQL (default SQL="rks-db query") and SQL_QUERY (optional).
# See _sql_querystring for parameter and search parameter replace.
# See _sql_select for SQL_COL results.
#
# BEWARE: don't use `_sql select ...` or $(_sql select) - SQL_COL will be empty (subshell execution)
#
# @global SQL SQL_QUERY (hash)
# @export SQL (=rks-db query)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @return boolean (if type=select - false = no result)
#--
function _sql {
	if test -z "$SQL"; then
		if test -s "/usr/local/bin/rks-db"; then
			SQL='rks-db query'
		else
			_abort "set SQL="
		fi
	fi

	local action query
	action="$1"
	query="$2"

	if [[ "$1" =~ ^(list|execute|select)_([a-z]+)$ ]]; then
		action="${BASH_REMATCH[1]}"
		query="$1"
		test -z "${SQL_QUERY[$query]}" && _abort "invalid action $action - no such query key $query"
	fi

	test -z "${SQL_QUERY[$query]}" || query="${SQL_QUERY[$query]}"
	query=$(_sql_querystring "$query")

	if test "$action" = "select"; then
		_sql_select "$query"
	elif test "$action" = "execute"; then
		_sql_execute "$query" "$3"
	elif test "$action" = "list"; then
		_sql_list "$query"
	else
		_abort "_sql(...) invalid first parameter [$1] - use select|execute|list or ACTION_QKEY"
	fi
}

