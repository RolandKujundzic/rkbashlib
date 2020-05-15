#!/bin/bash

#--
# Export remote ip adress REMOTE_IP and REMOTE_IP6.
#
# @export REMOTE_IP REMOTE_IP6
# shellcheck disable=SC2034
#--
function _remote_ip {
	_require_program curl

	local ip4_ip6
	ip4_ip6=$(curl -sSL --insecure 'https://dyn4.de/ip.php')

	REMOTE_IP=$(echo "$ip4_ip6" | awk '{print $1}')
	REMOTE_IP6=$(echo "$ip4_ip6" | awk '{print $2}')
}

