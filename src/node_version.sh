#!/bin/bash

#--
# Check node.js version. Install node and npm if missing. 
# Update to NODE_VERSION and NPM_VERSION if necessary.
# Use NODE_VERSION=v12.16.2 and NPM_VERSION=6.13.4 as default.
#
# @global NODE_VERSION NPM_VERSION
# @export NODE_VERSION NPM_VERSION
#--
function _node_version {
	test -z "$NODE_VERSION" && NODE_VERSION=v12.16.2
	test -z "$NPM_VERSION" && NPM_VERSION=6.14.4

	if ! command -v node >/dev/null || ! command -v npm >/dev/null; then
		_install_node 
	fi

	local node_ver npm_ver

	node_ver=$(node --version || _abort "node --version failed")
	[[ $(_ver3 "$node_ver") -lt $(_ver3 $NODE_VERSION) ]] && _install_node

	npm_ver=$(npm --version || _abort "npm --version failed")
	if [[ $(_ver3 "$npm_ver") -lt $(_ver3 $NPM_VERSION) ]]; then
		_msg "Update npm from $npm_ver to latest"
		_sudo "npm i -g npm"
	fi
}

