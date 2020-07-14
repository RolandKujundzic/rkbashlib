#!/bin/bash

#--
# Show list with $linebreak entries per line.
#
# @param list
# @param linebreak
# @param label (optional)
#--
function _show_list {
	local i a
	i=0

	if test -n "$3"; then
		echo ""
		_label "$3"
	fi

	for a in $1; do
		i=$((i+1))
		echo -n "$a "

		n=$((i%$2))
		test "$n" = "0" && echo ""
	done

	echo ""
}

