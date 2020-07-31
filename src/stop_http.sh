#!/bin/bash

#--
# Stop webserver (apache2, nginx) on port 80 if running.
# Ignore docker webservice on port 80.
#
# @os linux
#--
function _stop_http {
	_os_type linux

	if ! _is_running port:80; then
		_warn "no service on port 80"
		return
	fi

	if _is_running docker:80; then
		_warn "ignore docker service on port 80"
		return
	fi

	if _is_running nginx; then
		_service nginx stop
	elif _is_running apache; then
		_service apache2 stop
	fi
}

