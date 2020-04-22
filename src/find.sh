#!/bin/bash

#--
# Save found filesystem entries into FOUND.
#
# @param any paramter useable with find command
# @export FOUND Path Array
#--
function _find {
	FOUND=()
	local a=

	_require_program find

	while read a; do
		FOUND+=("$a")
	done <<< `find $@ 2>/dev/null`
}

