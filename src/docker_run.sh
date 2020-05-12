#!/bin/bash

#--
# Remove stopped docker container $1 (if found). Start docker container $1.
#
# @param name
# @param config file
# @global CURR WORKSPACE 
# shellcheck disable=SC2086
#--
function _docker_run {
	_docker_rm "$1"

	if ! test -z "$WORKSPACE" && ! test -z "$CURR" && test -d "$WORKSPACE/linux/rkdocker"; then
		_cd "$WORKSPACE/linux/rkdocker"
	else
		_abort "Export WORKSPACE (where $WORKSPACE/linux/rkdocker exists) and CURR=path/current/directory"
	fi

	local config

	if test -f "$CURR/$2"; then
		config="$CURR/$2"
	elif test -f "$2"; then
		config="$2"
	else
		_abort "No such configuration $CURR/$2 ($PWD/$2)"
	fi
	
  echo "DOCKER_NAME=$1 ./run.sh $config start"
  DOCKER_NAME=$1 ./run.sh $2 start

	_cd "$CURR"
}

