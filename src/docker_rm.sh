#!/bin/bash

#--
# Remove stopped docker container (if found).
#
# @param name
#--
function _docker_rm {
	_docker_stop "$1"

	if test -n "$(docker ps -a | grep "$1")"; then
		echo "docker rm $1"
		docker rm "$1"
	fi
}

