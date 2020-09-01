#!/bin/bash

#--
# Abort if '$1 --version' is lowner than $2.
# Use NO_ABORT=1 to return 1 if version is wrong.
#
# @param app name
# @param app version
# @return bool
#--
function _require_version {
	_require_program "$1"

	local version
	version="$($1 --version 2>/dev/null | sed -E 's/.+ version ([0-9]+\.[0-9]+)\.?([0-9]*).+/\1\2/')"

	if (( $(echo "$version < $2" | bc -l) )); then
		_abort "$1 --version < $2"
		return 1
	fi

	return 0
}

