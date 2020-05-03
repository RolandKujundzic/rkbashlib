#!/bin/bash

#--
# Split string "$2" at "$1" (export as $_SPLIT[@]).
# @param delimter
# @param string
# @export array _SPLIT
# @echo
#--
function _split {
	IFS="$1" read -ra _SPLIT <<< "$2"
	echo "${_SPLIT[@]}"
}

