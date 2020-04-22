#!/bin/bash

#--
# Remove stopped docker container $1 (if found). Start docker container $1.
#
# @param name
# @param config file
#--
function _docker_run {
	_docker_rm $1

	if ! test -z "$WORKSPACE" && ! test -z "$CURR" && test -d "$WORKSPACE/linux/rkdocker"; then
		_cd "$WORKSPACE/linux/rkdocker"
	else
		_abort "Export WORKSPACE (where $WORKSPACE/linux/rkdocker exists) and CURR=path/current/directory"
	fi

	local CONFIG=

	if test -f "$CURR/$2"; then
		CONFIG="$CURR/$2"
	elif test -f "$2"; then
		CONFIG="$2"
	else
		_abort "No such configuration $CURR/$2 ($PWD/$2)"
	fi
	
  echo "DOCKER_NAME=$1 ./run.sh $CONFIG start"
  DOCKER_NAME=$1 ./run.sh $2 start

	cd $CURR
}

