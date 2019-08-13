#!/bin/bash

#------------------------------------------------------------------------------
# Check if ip_address is ip6. IP can be empty if flag & 1.
#
# @param ip_address
# @param flag
# @require _abort 
#------------------------------------------------------------------------------
function _is_ip6 {
	local FLAG=$(($2 + 0))
	if test -z "$1" && test $((FLAG & 1)) = 1; then
		return;
	fi

	local is_ip6=`echo "$3" | \
		grep -E '^[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}\:[0-9a-f]{1,4}$'`

	if test -z "$is_ip6"; then
		_abort "Invalid ip6 [$1] use e.g. 2001:4dd1:4fa3:0:95b2:572a:1d5e:4df5"
	fi
}

