#!/bin/bash

#--
# Abort if ip_address of domain does not point to IP_ADDRESS.
# Call _ip_address first. Skip if CHECK_IP_OFF=1.
#
# @global IP_ADDRESS CHECK_IP_OFF
# @param domain
#--
function _check_ip {
	test "$CHECK_IP_OFF" = '1' && return
	local ip_ok ping4
	_require_program ping

	if ping -4 -c1 localhost &>/dev/null; then
		ping4="ping -4 -c 1"
	else
		ping4="ping -c 1"
	fi

	ip_ok=$($ping4 "$1" 2> /dev/null | grep "$IP_ADDRESS")
	test -z "$ip_ok" && _abort "$1 does not point to server ip $IP_ADDRESS"
}

