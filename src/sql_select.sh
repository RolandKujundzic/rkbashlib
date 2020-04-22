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
#--
function _sql_select {
	local QUERY="$1"
	test -z "$QUERY" && _abort "empty query in _sql_select"
	_require_global "_SQL"

	local DBOUT=`$_SQL "$QUERY" || _abort "$QUERY"`
	local LNUM=`echo "$DBOUT" | wc -l`

	_SQL_COL=()
	_SQL_COL[_all]="$DBOUT"
	_SQL_COL[_rows]=$((LNUM - 1))

	if test $LNUM -eq 2; then
		local LINE1=`echo "$DBOUT" | head -1`
		local LINE2=`echo "$DBOUT" | tail -1`
		local CKEY; local CVAL; local i;

		IFS=$'\t' read -ra CKEY <<< "$LINE1"
		IFS=$'\t' read -ra CVAL <<< "$LINE2"

		for (( i=0; i < ${#CKEY[@]}; i++ )); do
			_SQL_COL[${CKEY[$i]}]="${CVAL[$i]}"
		done

		return 0  # true single line result
	elif test $LNUM -lt 2; then
		return 1  # false = no result
	else
		_abort "_sql select: multi line result ($LNUM lines)\nUse _sql list ..."
	fi
}

