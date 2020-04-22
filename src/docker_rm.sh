#!/bin/bash

#--
# Remove stopped docker container (if found).
#
# @param name
#--
function _docker_rm {
	_docker_stop "$1"

	local HAS_CONTAINER=`docker ps -a | grep "$1"`

	if ! test -z "$HAS_CONTAINER"; then
		echo "docker rm $1"
		docker rm "$1"
	fi
}

