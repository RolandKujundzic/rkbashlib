#!/bin/bash

#--
# Check if ip_address is ip4.
#
# @param ip_address
# @param 2^n flag (1 = ip can be empty)
#--
function _is_ip4 {
	local x flag=$(($2 + 0))

	[[ -z "$1" && $((flag & 1)) = 1 ]] && return

	x='\.[0-9]{1,3}'
	if test -z "$(echo "$1" | grep -E "^[0-9]{1,3}$x$x$x\$")"; then
		_abort "Invalid ip4 address [$1] use e.g. 32.123.7.38"
	fi
}

