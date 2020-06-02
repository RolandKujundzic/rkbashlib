#!/bin/bash

#--
# Print sql select result table.
#
# @global SQL
# @param type query
#--
function _sql_list {
	local query="$1"
	test -z "$query" && _abort "empty query in _sql_list"
	_require_global SQL

	$SQL "$query" || _abort "$query"
}

