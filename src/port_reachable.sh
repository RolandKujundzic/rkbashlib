#!/bin/bash

#--
# Check if port $2 on server $1 is reachable
#
# @param string ip or server name
# @param port
# @return bool
#--
function _port_reachable {
	if nc -zv -w2 "$1" "$2" 2>/dev/null; then
		return 0
	else
		return 1
	fi
}

