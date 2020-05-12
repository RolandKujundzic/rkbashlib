#!/bin/bash

#--
# Abort with error message. Process name is either
# apache|nginx|docker:N|port:N (N is port number) 
# or [n]ame. Example:
#
# if test _is_running apache; then
# if test _is_running port:80; then
# if test _is_running [m]ysql; then
#
# @param Process name or expression apache|ngnix|docker:N|port:N|[n]ame
# @os linux
# @return bool
# shellcheck disable=SC2009
#--
function _is_running {
	_os_type linux
	local rx out res
	res=0

	if test "$1" = 'apache'; then
		rx='[a]pache2.*k start'
	elif test "$1" = 'nginx'; then
		rx='[n]ginx.*master process'
	elif test "${1:0:7}" = 'docker:'; then
		rx="[d]ocker-proxy.* -host-port ${1:7}"
	elif test "${1:0:5}" = 'port:'; then
		out=$(netstat -tulpn 2>/dev/null | grep -E ":${1:5} .+:* .+LISTEN.*")
	else
		_abort "invalid [$1] use apache|nginx|docker:PORT|port:N|rx:[n]ame"
	fi

	test -z "$rx" || out=$(ps aux 2>/dev/null | grep -E "$rx")

	test -z "$out" && res=1
	return $res	
}

