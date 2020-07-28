#!/bin/bash

#--
# Print warning (green color message to stdout and stderr)
#
# @param message
#--
function _ok {
	echo -e "\033[0;32m$1\033[0m" 1>&2
}

