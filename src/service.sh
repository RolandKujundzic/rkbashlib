#!/bin/bash

#--
# Control service start|stop|restart|reload|enable|disable
# @param service name
# @param action
#--
function _service {
	test -z "$1" && _abort "empty service name"
	test -z "$2" && _abort "empty action"

	local has_service
	has_service=$(service --status-all | grep -E '\s+'"$1"'$')
	test -z "$has_service" && _abort "no such service $1"

	[[ ! "$has_service" =~ + && "$1" != 'enable' ]] && _abort "$1 is disabled"

	_msg "service $1 $2"
	_sudo "service $1 $2"
}

