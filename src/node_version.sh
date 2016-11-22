#!/bin/bash

#------------------------------------------------------------------------------
# Check node.js version. Update to NPM_VERSION
#
# @global NODE_VERSION
# @global NPM_VERSION
# @require ver3
# @require abort
#------------------------------------------------------------------------------
function _node_version {
	local CURR_NODE_VERSION=`node --version`
	if [ $(ver3 $CURR_NODE_VERSION) -lt $(ver3 $NODE_VERSION) ]
	then
		_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
	fi

	local CURR_NPM_VERSION=`npm --version`
	if [ $(ver3 $CURR_NPM_VERSION) -lt $(ver3 $NPM_VERSION) ]
	then
		echo -e "Update npm from $CURR_NPM_VERSION to latest\nType in sudo password if necessary"
		sudo npm install npm@latest -g
		sudo npm update --depth=0 -g
	fi
}

