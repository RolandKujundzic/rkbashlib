#!/bin/bash

#--
# Stop running docker container (if found).
#
# @param name
#--
function _docker_stop {
	if test -n "$(docker ps | grep "$1")"; then
		echo "docker stop $1"
		docker stop "$1"
	fi
}

