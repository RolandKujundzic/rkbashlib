#!/bin/bash

#--
# Export remote ip adress REMOTE_IP and REMOTE_IP6.
#
# @export REMOTE_IP REMOTE_IP6
# @require _abort _require_program
#--
function _remote_ip {
	_require_program curl

	local IP4_IP6=`curl -sSL https://dyn4.de/ip.php`

	REMOTE_IP=`echo "$IP4_IP6" | awk '{print $1}'`
	REMOTE_IP6=`echo "$IP4_IP6" | awk '{print $2}'`
}

