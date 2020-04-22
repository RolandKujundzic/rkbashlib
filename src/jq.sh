#!/bin/bash

#--
# Query json file value. jq warpper.
#
# @param key
# @param json file (optional if JQ_FILE is set)
#--
function _jq {
	local KEY="$1"
	local FILE="${2:-$JQ_FILE}"

	test -z "$KEY" && _abort "empty json key"
	_require_file "$FILE"
	_require_program "jq" "jq"

	jq -r ".$KEY" "$FILE" || _abort "jq -r '.$KEY' '$FILE'"
}

