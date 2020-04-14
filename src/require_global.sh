#!/bin/bash

#--
# Abort if global variable is empty. With bash version >= 4.4 check works even
# for arrays. If bash version < 4.4 export HAS_HASH_$1
#
# @param name list (e.g. "GLOBAL", "GLOB1 GLOB2 ...", GLOB1 GLOB2 ...)
# @require _abort
#--
function _require_global {
	local BASH_VERSION=`bash --version | grep -iE '.+bash.+version [0-9\.]+' | sed -E 's/^.+version ([0-9]+)\.([0-9]+)\..+$/\1.\2/i'`

	local a=; local has_hash=; 
	for a in $@; do
		has_hash="HAS_HASH_$a"

		if (( $(echo "$BASH_VERSION >= 4.4" | bc -l) )); then
			typeset -n ARR=$a

			if test -z "$ARR" && test -z "${ARR[@]:1:1}"; then
				_abort "no such global variable $a"
			fi
		elif test -z "${a}" && test -z "${has_hash}"; then
			_abort "no such global variable $a - add HAS_HASH_$a if necessary"
		fi
	done
}
