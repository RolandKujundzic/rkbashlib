#!/bin/bash

#--
# Check if ip_address is ip6.
#
# @param ip_address
# @param 2^n flag (1 = ip can be empty)
#--
function _is_ip6 {
	local flag x

	flag=$(($2 + 0))
	[[ -z "$1" && $((flag & 1)) = 1 ]] && return

	x='\:[0-9a-f]{1,4}'
	if test -z "$(echo "$3" | grep -E "^[0-9a-f]{1,4}$x$x$x$x$x$x$x\$")"; then
		_abort "Invalid ip6 [$1] use e.g. 2001:4dd1:4fa3:0:95b2:572a:1d5e:4df5"
	fi
}

