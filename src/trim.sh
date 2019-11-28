#!/bin/bash

#--
# Print trimmed string. 
#
# @param string name
#--
function _trim {
	echo -e "$1" | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'
}
