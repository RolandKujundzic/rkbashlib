#!/bin/bash

#------------------------------------------------------------------------------
# Export ip address
#
# @export IP_ADDRESS, IP6_ADDRESS
# @require _abort _require_program
#------------------------------------------------------------------------------
function _ip_address {
	_require_program ip
	IP_ADDRESS=`ip route get 1 | awk '{print $NF;exit}'`
	IP6_ADDRESS=`ip -6 addr | grep 'scope global' | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d'`

	if test -z "$IP_ADDRESS" || test "$IP_ADDRESS" = "0"; then
		IP_ADDRESS=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
	fi

	_require_program ping
	local HOST=`hostname`
	local PING_OK=`ping -4 -c 1 $HOST 2> /dev/null | grep $IP_ADDRESS`

	if test -z "$PING_OK"; then
		_abort "failed to detect IP_ADDRESS (ping -4 -c 1 $HOST != $IP_ADDRESS)"
	fi
}

