#!/bin/bash

#--
# Abort if ip_address of domain does not point to IP_ADDRESS.
# Call _ip_address first.
#
# @global IP_ADDRESS
# @param domain
#--
function _check_ip {
	_require_program ping

	local IP_OK=`ping -4 -c 1 "$1" 2> /dev/null | grep "$IP_ADDRESS"`
	if test -z "$IP_OK"; then
		_abort "$1 does not point to server ip $IP_ADDRESS"
	fi
}


