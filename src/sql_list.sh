#!/bin/bash

#--
# Print sql select result table.
#
# @global _SQL
# @param type query
#--
function _sql_list {
	local QUERY="$1"
	test -z "$QUERY" && _abort "empty query in _sql_list"
	_require_global "_SQL"

	$_SQL "$QUERY" || _abort "$QUERY"
}

