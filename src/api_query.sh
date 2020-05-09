#!/bin/bash

declare -A API_QUERY

#--
# Query $API_QUERY[url]/$1. Set $API_QUERY[log|out]. Abort if "query failed|no result".
#
# @param string query type curl|func|wget
# @param string query string
# @param hash query parameter
# @global API_QUERY
# shellcheck disable=SC2154
#--
function _api_query {
	test -z "$1" && _abort "missing query type - use curl|func|wget"
	test -z "$2" && _abort "missing query string"

	local out_f log_f err_f
	out_f="$RKSCRIPT_DIR/api_query.res"	
	log_f="$RKSCRIPT_DIR/api_query.log"	
	err_f="$RKSCRIPT_DIR/api_query.err"

	echo '' > "$out_f"

	API_QUERY[out]=
	API_QUERY[log]=

	if test "$1" = "wget"; then
		_msg "wget ${API_QUERY[url]}/$2"
		wget -q -O "$out_f" "${API_QUERY[url]}/$2" >"$log_f" 2>"$err_f" || _abort "wget failed"
		test -s "$out_f" || _abort "no result"
	else
		_abort "$1 api query not implemented"
	fi

	test -s "$out_f" && API_QUERY[out]=$(cat "$out_f")
	test -s "$log_f" && API_QUERY[log]=$(cat "$log_f")
	test -z "$err_f" || _abort "non-empty error log"
}

