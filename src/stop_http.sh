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
		echo "no service on port 80"
		return
	fi

	if _is_running docker:80; then
		echo "ignore docker service on port 80"
		return
	fi

	if _is_running nginx; then
		echo "stop nginx"
		sudo service nginx stop
		return
	fi

	if _is_running apache; then
		echo "stop apache2"
		sudo service apache2 stop
		return
	fi
}

