#!/bin/bash

#------------------------------------------------------------------------------
# Show where php string function needs to change to mb_* version.
#------------------------------------------------------------------------------
function _mb_check {
	# do not use ereg*
	MB_FUNCTIONS="parse_str split stripos stristr strlen strpos strrchr strrichr strripos strrpos strstr strtolower strtoupper strwidth substr_count substr"

	for a in $MB_FUNCTIONS
	do
		FOUND=`grep -d skip -r $a'(' src/*.php | grep -v 'mb_'$a'('`

		if ! test -z "$FOUND"
		then
			echo "$FOUND"
		fi
	done
}

