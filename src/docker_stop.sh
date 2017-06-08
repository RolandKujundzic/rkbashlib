#!/bin/bash

#------------------------------------------------------------------------------
# Stop running docker container (if found).
#
# @param name
#------------------------------------------------------------------------------
function _docker_stop {
	local HAS_CONTAINER=`docker ps | grep "$1"`

	if ! test -z "$HAS_CONTAINER"; then
		echo "docker stop $1"
		docker stop "$1"
	fi
}

