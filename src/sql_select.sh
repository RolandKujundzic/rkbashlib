#!/bin/bash

declare -A SQL_COL

#--
# Run sql select query. Save result of select query to SQL_COL. 
# Add SQL_COL[_all] (=STDOUT) and SQL_COL[_rows].
#
# BEWARE: don't use `_sql_select ...` or $(_sql_select) - SQL_COL will be empty (subshell execution)
#
# @global SQL SQL_COL (hash)
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
	_require_global SQL

	dbout=$($SQL "$query" || _abort "$query")
	lnum=$(echo "$dbout" | wc -l)

	SQL_COL=()
	SQL_COL[_all]="$dbout"
	SQL_COL[_rows]=$((lnum - 1))

	if test "$lnum" -eq 2; then
		line1=$(echo "$dbout" | head -1)
		line2=$(echo "$dbout" | tail -1)

		IFS=$'\t' read -ra ckey <<< "$line1"
		IFS=$'\t' read -ra cval <<< "$line2"

		for (( i=0; i < ${#ckey[@]}; i++ )); do
			SQL_COL[${ckey[$i]}]="${cval[$i]}"
		done

		return 0  # true single line result
	elif test "$lnum" -lt 2; then
		return 1  # false = no result
	else
		_abort "_sql select: multi line result ($lnum lines)\nUse _sql list ..."
	fi
}

