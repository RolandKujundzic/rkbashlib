#!/bin/bash

declare -A API_QUERY

#--
# Query $API_QUERY[url]/$1. Set $API_QUERY[log|out]. Abort if "query failed|no result".
#
# @param string query type curl|func|wget
# @param string query string
# @param hash query parameter
# @global API_QUERY
#--
function _api_query {
	test -z "$1" && _abort "missing query type - use curl|func|wget"
	test -z "$2" && _abort "missing query string"

	local OUT_F="$RKSCRIPT_DIR/api_query.res"	
	local LOG_F="$RKSCRIPT_DIR/api_query.log"	
	local ERR_F="$RKSCRIPT_DIR/api_query.err"

	echo '' > "$OUT_F"

	API_QUERY[out]=
	API_QUERY[log]=

	if test "$1" = "wget"; then
		_msg "wget ${API_QUERY[url]}/$2"
		wget -q -O "$OUT_F" "${API_QUERY[url]}/$2" >"$LOG_F" 2>"$ERR_F" || _abort "wget failed"
		test -s "$OUT_F" || _abort "no result"
	else
		_abort "$1 api query not implemented"
	fi

	test -s "$OUT_F" && API_QUERY[out]=`cat "$OUT_F"`
	test -s "$LOG_F" && API_QUERY[log]=`cat "$LOG_F"`
	test -z "$ERR_F" || _abort "non-empty error log"
}

