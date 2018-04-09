#!/bin/bash

#------------------------------------------------------------------------------
# Export ip address
#
# @export IP_ADDRESS
# @require _abort
#------------------------------------------------------------------------------
function _ip_address {
	IP_ADDRESS=`ip route get 1 | awk '{print $NF;exit}'`

	if test -z "$IP_ADDRESS"; then
		IP_ADDRESS=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
	fi

	local HOST=`hostname`
	local PING_OK=`ping -c 1 $HOST 2> /dev/null | grep $IP_ADDRESS`

	if test -z "$PING_OK"; then
		_abort "failed to detect IP_ADDRESS (ping -c 1 $HOST != $IP_ADDRESS)"
	fi
}

