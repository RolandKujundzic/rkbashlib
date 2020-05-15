#!/bin/bash

#--
# If query is longer than 60 chars return "${1:0:60} ...".
# @param query
# @echo 
#--
function _sql_echo {
	local query
	query="$1"
	test ${#query} -gt 60 && query="${query:0:60} ..."
	echo -n "$query"
}

