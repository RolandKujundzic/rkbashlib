#!/bin/bash

#--
# Split string "$2" at "$1" (export as $_SPLIT[@]).
# @param delimter
# @param string
# @export array _SPLIT
#--
function _split {
	IFS="$1" read -ra _SPLIT <<< "$2"
}

