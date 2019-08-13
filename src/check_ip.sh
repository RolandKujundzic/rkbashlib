#!/bin/bash

#------------------------------------------------------------------------------
# Abort if ip_address is ip4 and points to IP_ADDRESS.
# Call _ip_address first.
#
# @global IP_ADDRESS
# @param ip_address
# @require _abort _require_program _is_ip4
#------------------------------------------------------------------------------
function _check_ip {
	_require_program ping

	_is_ip4 "$1"

	local IP_OK=`ping -4 -c 1 "$1" 2> /dev/null | grep "$IP_ADDRESS"`
	if test -z "$IP_OK"; then
		_abort "$1 does not point to server ip $IP_ADDRESS"
	fi
}


