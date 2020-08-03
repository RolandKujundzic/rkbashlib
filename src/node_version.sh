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

	if [[ $(_version node 1) -lt $(_version $NODE_VERSION 1) ]]; then
		_install_node
	fi

	if [[ $(_version npm 1) -lt $(_version $NPM_VERSION 1) ]]; then
		_msg "Update npm to latest"
		_sudo "npm i -g npm"
	fi
}

