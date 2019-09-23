#!/bin/bash

#------------------------------------------------------------------------------
# Abort if global variable is empty. With bash version >= 4.4 check works even
# for arrays.
#
# @param variable name (e.g. "GLOBAL" or "GLOB1 GLOB2 ...")
# @require _abort
#------------------------------------------------------------------------------
function _require_global {
	local BASH_VERSION=`bash --version | grep -E '.+bash.+Version [0-9\.]+' | sed -E 's/^.+Version ([0-9]+)\.([0-9]+)\..+$/\1.\2/'`

	local a=; for a in $1; do
		if (( $(echo "$BASH_VERSION >= 4.4" | bc -l) )); then
			typeset -n ARR=$a

			if test -z "$ARR" && test -z "${ARR[@]:1:1}"; then
				echo "no such global variable $a"
			fi
		elif test -z "${!a}"; then
			echo "no such global variable $a"
		fi
	done
}
