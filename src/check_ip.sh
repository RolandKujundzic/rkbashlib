#!/bin/bash

#------------------------------------------------------------------------------
# Abort if ip_address does not point to IP_ADDRESS
#
# @global IP_ADDRESS
# @param ip_address
# @require _abort
#------------------------------------------------------------------------------
function _check_ip {
	local IP_OK=`ping4 -c 1 "$1" 2> /dev/null | grep "$IP_ADDRESS"`

	if test -z "$IP_OK"; then
		_abort "$1 does not point to server ip $IP_ADDRESS"
	fi
}


