#!/bin/bash

#--
# Abort if program (function) $1 does not exist (and $2 is not 1).
#
# @param program
# @param string default='' (abort if missing), 1=return false, apt:xxx (install xxx if missing)
# @return bool (if $2==1)
#--
function _require_program {
	local ptype
	ptype=$(type -t "$1")

	test "$ptype" = "function" && return
	command -v "$1" >/dev/null 2>&1 && return
	command -v "./$1" >/dev/null 2>&1 && return

	if test "${2:0:4}" = "apt:"; then
		_apt_install "${2:4}"
	elif test -z "$2"; then
		echo "No such program [$1]"
		exit 1
	else
		return 1
	fi
}

