#!/bin/bash

#--
# Export ip address as IP_ADDRESS (ip4) and IP6_ADDRESS (ip6) (and DYNAMIC_IP).
#
# @export IP_ADDRESS IP6_ADDRESS DYNAMIC_IP
# shellcheck disable=SC2034
#--
function _ip_address {
	local ip6_dyn host ping_ok
	_require_program ip

	IP_ADDRESS=$(ip route get 1 | grep -E ' src [0-9\.]+ uid ' | sed -e 's/.* src //' | sed -e 's/ uid.*//')
	if test -z "$IP_ADDRESS"; then
		IP_ADDRESS=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
	fi

	IP6_ADDRESS=$(ip -6 addr | grep 'scope global' | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')
	ip6_dyn=$(ip -6 addr | grep 'scope global temporary dynamic' | awk '{print $2}' | sed -e 's/\/[0-9]*$//')
	if ! test -z "$ip6_dyn"; then
		IP6_ADDRESS="$ip6_dyn"
		DYNAMIC_IP=1
	fi

	local ping4
	_require_program ping
  if ping -4 -c1 localhost &>/dev/null; then
    ping4="ping -4 -c 1"
  else
    ping4="ping -c 1"
  fi

	host=$(hostname)
	ping_ok=$($ping4 "$host" 2>/dev/null | grep "$IP_ADDRESS")

	if test -z "$ping_ok"; then
		ping_ok=$($ping4 "$host" 2>/dev/null | grep "127.0.")

		if test -z "$ping_ok"; then
			_abort "failed to detect IP_ADDRESS ($ping4 $host != $IP_ADDRESS)"
		fi
	fi
}

