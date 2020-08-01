#!/bin/bash

#--
# Control service start|stop|restart|reload|enable|disable
# @param service name
# @param action
#--
function _service {
	test -z "$1" && _abort "empty service name"
	test -z "$2" && _abort "empty action"

	local is_active
	is_active=$(systemctl is-active "$1")

	if [[ "$is_active" != 'active' && ! "$2" =~ start && ! "$2" =~ able ]]; then
		_abort "$is_active service $1"
	fi

	if test "$2" = 'status'; then
		_ok "$1 is active"
		return
	fi

	_msg "systemctl $2 $1"
	_sudo "systemctl $2 $1"
}

