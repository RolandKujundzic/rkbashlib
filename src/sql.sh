#!/bin/bash

_SQL=
declare -A _SQL_QUERY
declare -A _SQL_PARAM

#--
# Run sql select or execute query. Query is either $2 or _SQL_QUERY[$2] (if set). 
# If $1=select print result of select query. If $1=execute ask if query $2 should
# be execute (default=y) or skip. Set _SQL (e.g. SQL="rks-db_connect query") and
# _SQL_QUERY (optional).
#
# @global _SQL _SQL_QUERY (hash) _SQL_PARAM (hash)
# @param type select|execute
# @param query or SQL_QUERY key
# @require
#--
function _sql {
	test -z "$_SQL" && _abort "set _SQL="
	
	local QUERY="$2"
	if ! test -z "${_SQL_QUERY[$2]}"; then
		QUERY="${_SQL_QUERY[$2]}"
		local a=

		for a in "${!_SQL_PARAM[@]}"; do
			echo "key  : $a"
			echo "value: ${_SQL_PARAM[$a]}"
			QUERY="${QUERY//\{:=$a\}/${_SQL_PARAM[$a]}}"
		done
	fi

	if test "$1" = "select"; then
		$_SQL "$QUERY" | tail -1
	elif test "$1" = "execute"; then
		local CONFIRM=
		echo -n "$QUERY [y] "
	  read -n1 CONFIRM

		if test "$CONFIRM" = "y"; then
			$_SQL "$QUERY"
			echo " ... query executed"
		else
			echo " ... skip"
		fi
	else
		_abort "_sql(...) invalid first parameter [$1] - use select|execute"
	fi
}

