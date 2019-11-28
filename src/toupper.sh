#!/bin/bash

#--
# Return uppercase text. 
#
# @param string txt
#--
function _toupper {
	printf '%s\n' "$1" | awk '{ print toupper($0) }'
}
