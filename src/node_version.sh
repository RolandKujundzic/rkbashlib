#!/bin/bash

#--
# Check node.js version. Install node and npm if missing. 
# Update to NODE_VERSION and NPM_VERSION if necessary.
# Use NODE_VERSION=v12.16.2 and NPM_VERSION=6.13.4 as default.
#
# @global NODE_VERSION NPM_VERSION APP_PREFIX APP_FILE_LIST APP_DIR_LIST APP_SYNC
# @require _ver3 _msg _install_node _sudo
#--
function _node_version {
	test -z "$NODE_VERSION" && NODE_VERSION=v12.16.2
	test -z "$NPM_VERSION" && NPM_VERSION=6.14.4

	local has_node=`which node`
	local has_npm=`which npm`
	[[ -z "$has_node" || -z "$has_npm" ]] && _install_node 

	local curr_node_version=`node --version || _abort "node --version failed"`
	[[ $(_ver3 $curr_node_version) -lt $(_ver3 $NODE_VERSION) ]] && _install_node

	local curr_npm_version=`npm --version || _abort "npm --version failed"`
	if [[ $(_ver3 $curr_npm_version) -lt $(_ver3 $NPM_VERSION) ]]; then
		_msg "Update npm from $CURR_NPM_VERSION to latest"
		_sudo "npm i -g npm"
	fi
}

