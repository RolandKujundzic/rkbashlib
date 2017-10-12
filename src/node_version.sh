#!/bin/bash

#------------------------------------------------------------------------------
# Check node.js version. Install node and npm if missing. 
# Update to NODE_VERSION and NPM_VERSION if necessary.
# Use NODE_VERSION=v6.11.0 and NPM_VERSION=5.0.3 ad default.
#
# @global NODE_VERSION NPM_VERSION APP_PREFIX APP_FILE_LIST APP_DIR_LIST
# @require ver3 require_global install_node sudo
#------------------------------------------------------------------------------
function _node_version {

	if test -z "$NODE_VERSION"; then
		NODE_VERSION=v6.11.4
	fi

	if test -z "$NPM_VERSION"; then
		NPM_VERSION=5.0.3
	fi

	local HAS_NODE=`which node`
	local HAS_NPM=`which npm`

	if test -z "$HAS_NODE" || test -z "$HAS_NPM"; then
		_install_node
	fi

	_require_global "NODE_VERSION NPM_VERSION"

	local CURR_NODE_VERSION=`node --version`

	if [ $(_ver3 $CURR_NODE_VERSION) -lt $(_ver3 $NODE_VERSION) ]
	then
		_install_node
	fi

	local CURR_NPM_VERSION=`npm --version`
	if [ $(_ver3 $CURR_NPM_VERSION) -lt $(_ver3 $NPM_VERSION) ]
	then
		echo -e "Update npm from $CURR_NPM_VERSION to latest"
		_sudo "npm i -g npm"
	fi
}

