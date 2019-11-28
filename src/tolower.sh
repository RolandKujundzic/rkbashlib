#!/bin/bash

#--
# Return lowercase text. 
#
# @param string txt
#--
function _tolower {
	printf '%s\n' "$1" | awk '{ print tolower($0) }'
}
