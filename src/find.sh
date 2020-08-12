#!/bin/bash

#--
# Save found filesystem entries into FOUND.
#
# @example:
# _find root/dir '-name \*.html'
# for ((i=0; i < ${#FOUND[@]}; i++)); do
#   echo "$i: [${FOUND[$i]}]"
# done
# @:
#
# @param root directory 
# @param find expression e.g. "-name '*.html'"
# @export FOUND Path Array
# shellcheck disable=SC2086
#--
function _find {
	FOUND=()
	local a

	_require_program find
	_require_dir "$1"

	while read -r a; do
		FOUND+=("$a")
	done < <(eval "find '$1' $2" || _abort "find '$1' $2")
}

