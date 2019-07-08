#!/bin/bash

#------------------------------------------------------------------------------
# Show list with $linebreak entries per line.
#
# @param list
# @param linebreak
#------------------------------------------------------------------------------
function _show_list {
	local i=0
	local a=

	for a in $1
	do
		i=$(($i+1))
		echo -n "$a "

		n=$(($i%$2))
		if test "$n" = "0"; then
			echo ""
		fi
	done
}
