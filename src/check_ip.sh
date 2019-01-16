#!/bin/bash

#------------------------------------------------------------------------------
# Abort if ip_address does not point to IP_ADDRESS.
# Call _ip_address first.
#
# @global IP_ADDRESS, PING4
# @param ip_address
# @require _abort
#------------------------------------------------------------------------------
function _check_ip {
	local IP_OK=`$PING4 -c 1 "$1" 2> /dev/null | grep "$IP_ADDRESS"`

	if test -z "$IP_OK"; then
		_abort "$1 does not point to server ip $IP_ADDRESS"
	fi
}


