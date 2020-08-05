#!/bin/bash

#--
# Include shell script $1
# @param shell script path
# shellcheck disable=SC1090 
#--
function _include {
	_require_file "$1"
	_msg "include $1"
	source "$1" || _abort "source '$1'"
}

