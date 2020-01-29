#!/bin/bash

#--
# If query is longer than 60 chars return "${1:0:60} ...".
# @param query
# @echo 
#--
function _sql_echo {
	local QUERY="$1"
	test ${#QUERY} -gt 60 && QUERY="${QUERY:0:60} ..."
	echo -n $QUERY
}

