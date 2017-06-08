#!/bin/bash

#------------------------------------------------------------------------------
# Remove stopped docker container (if found).
#
# @param name
# @require docker_stop
#------------------------------------------------------------------------------
function _docker_rm {
	_docker_stop

	local HAS_CONTAINER=`docker ps -a | grep "$1"`

	if ! test -z "$HAS_CONTAINER"; then
		echo "docker rm $1"
		docker rm "$1"
	fi
}

