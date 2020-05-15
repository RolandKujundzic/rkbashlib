#!/bin/bash

declare -A _SQL_COL

#--
# Run sql select query. Save result of select query to _SQL_COL. 
# Add _SQL_COL[_all] (=STDOUT) and _SQL_COL[_rows].
#
# BEWARE: don't use `_sql_select ...` or $(_sql_select) - _SQL_COL will be empty (subshell execution)
#
# @global _SQL _SQL_COL (hash)
# @export SQL (=rks-db query)
# @param type select|execute
# @param query or SQL_QUERY key
# @param flag (1=execute sql without confirmation)
# @return boolean (if type=select - false = no result)
# shellcheck disable=SC2034
#--
function _sql_select {
	local dbout lnum line1 line2 query i ckey cval
	query="$1"
	test -z "$query" && _abort "empty query in _sql_select"
	_require_global "_SQL"

	dbout=$($_SQL "$query" || _abort "$query")
	lnum=$(echo "$dbout" | wc -l)

	_SQL_COL=()
	_SQL_COL[_all]="$dbout"
	_SQL_COL[_rows]=$((lnum - 1))

	if test "$lnum" -eq 2; then
		line1=$(echo "$dbout" | head -1)
		line2=$(echo "$dbout" | tail -1)

		IFS=$'\t' read -ra ckey <<< "$line1"
		IFS=$'\t' read -ra cval <<< "$line2"

		for (( i=0; i < ${#ckey[@]}; i++ )); do
			_SQL_COL[${ckey[$i]}]="${cval[$i]}"
		done

		return 0  # true single line result
	elif test "$lnum" -lt 2; then
		return 1  # false = no result
	else
		_abort "_sql select: multi line result ($lnum lines)\nUse _sql list ..."
	fi
}

