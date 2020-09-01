#!/bin/bash

#--
# Abort if program (function) $1 does not exist (and $2 is not 1).
#
# @param program
# @param string default='' (abort if missing), 1=return false, apt:xxx (install xxx if missing)
# @return bool (if $2==1 or NO_ABORT=1)
#--
function _require_program {
	local ptype
	ptype=$(type -t "$1")

	test "$ptype" = "function" && return 0
	command -v "$1" >/dev/null 2>&1 && return 0
	command -v "./$1" >/dev/null 2>&1 && return 0

	if test "${2:0:4}" = "apt:"; then
		_apt_install "${2:4}"
		return 0
	fi

	[[ -n "$2" || "$NO_ABORT" = 1 ]] && return 1

	# don't use _msg or _abort
	echo "No such program [$1]"
	exit 1
}

