#!/bin/bash

#--
# Save found filesystem entries into FOUND.
#
# @param root directory 
# @param find expression e.g. -name *.html
# @export FOUND Path Array
# shellcheck disable=SC2086
#--
function _find {
	FOUND=()
	local a=

	_require_program find
	_require_dir "$1"

	while read -r a; do
		FOUND+=("$a")
	done <<< "$(find "$1" $2 2>/dev/null)"
}

