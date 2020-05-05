#!/bin/bash

#--
# Split string "$2" at "$1" (export as $SPLIT[@]).
# @param delimter
# @param string (or /dev/stdin if unset)
# @export array SPLIT
# @echo
#--
function _split {
	local txt
	test -z "${2+x}" && txt=$(cat /dev/stdin) || txt="$2"

	IFS="$1" read -ra SPLIT <<< "$txt"
	echo "${SPLIT[@]}"
}

