#!/bin/bash

#--
# Print warning (red color message to stdout and stderr)
#
# @param message
#--
function _warn {
	echo -e "\033[0;31m$1\033[0m" 1>&2
}

