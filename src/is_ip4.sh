#!/bin/bash

#--
# Check if ip_address is ip4. IP can be empty if flag & 1.
#
# @param ip_address
# @param flag
#--
function _is_ip4 {
	local FLAG=$(($2 + 0))
	if test -z "$1" && test $((FLAG & 1)) = 1; then
		return;
	fi

	local is_ip4=`echo "$1" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'`

	if test -z "$is_ip4"; then
		_abort "Invalid ip4 address [$1] use e.g. 32.123.7.38"
	fi
}

