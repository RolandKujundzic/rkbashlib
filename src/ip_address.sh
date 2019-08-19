#!/bin/bash

#------------------------------------------------------------------------------
# Export ip address as IP_ADDRESS (ip4) and IP6_ADDRESS (ip6).
#
# @export IP_ADDRESS, IP6_ADDRESS
# @require _abort _require_program
#------------------------------------------------------------------------------
function _ip_address {
	_require_program ip

	IP_ADDRESS=`ip route get 1 | grep -E ' src [0-9\.]+ uid ' | sed -e 's/.* src //' | sed -e 's/ uid.*//'`
	IP6_ADDRESS=`ip -6 addr | grep 'scope global' | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d'`

	if test -z "$IP_ADDRESS"; then
		IP_ADDRESS=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
	fi

	_require_program ping
	local host=`hostname`
	local ping_ok=`ping -4 -c 1 $host 2> /dev/null | grep $IP_ADDRESS`

	if test -z "$ping_ok"; then
		_abort "failed to detect IP_ADDRESS (ping -4 -c 1 $host != $IP_ADDRESS)"
	fi
}

