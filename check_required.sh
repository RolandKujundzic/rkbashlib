#!/bin/bash

#------------------------------------------------------------------------------
# Check if @require in file declares all required functions
#
# @param string file
#------------------------------------------------------------------------------
function _check_require {
	local REQUIRE=`grep @require $1`" "
	local FOUND=

	_required_rkscript $1

	echo "$1 requires: $REQUIRED_RKSCRIPT"

	for a in $REQUIRED_RKSCRIPT; do
		FOUND=`echo "$REQUIRE" | grep "$a "`
		if test -z "$FOUND"; then
			_abort "missing $a in @require of $1"
		fi
	done
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

RKSCRIPT_PATH="."

INCLUDE="abort scan_rkscript_src require_global cd required_rkscript"
for a in $INCLUDE; do
	. "$RKSCRIPT_PATH/src/$a"".sh"
done

_scan_rkscript_src

for a in src/*.sh; do
	_check_require $a
done

