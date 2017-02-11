#!/bin/bash

#------------------------------------------------------------------------------
# Check node.js version. Update to NPM_VERSION
#
# @global NODE_VERSION, NPM_VERSION
# @require ver3, abort, require_global
#------------------------------------------------------------------------------
function _node_version {
	_require_global "NODE_VERSION NPM_VERSION"

	local CURR_NODE_VERSION=`node --version`
	if [ $(_ver3 $CURR_NODE_VERSION) -lt $(_ver3 $NODE_VERSION) ]
	then
		_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
	fi

	local CURR_NPM_VERSION=`npm --version`
	if [ $(_ver3 $CURR_NPM_VERSION) -lt $(_ver3 $NPM_VERSION) ]
	then
		echo -e "Update npm from $CURR_NPM_VERSION to latest\nType in sudo password if necessary"
		sudo npm install npm@latest -g
		sudo npm update --depth=0 -g
	fi
}

