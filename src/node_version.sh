#!/bin/bash

#------------------------------------------------------------------------------
# Check node.js version
#
# @global NODE_VERSION
# @require ver3
# @require abort
#------------------------------------------------------------------------------
function _node_version {
	local CURR_NODE_VERSION=`node --version`

	if [ $(ver3 $CURR_NODE_VERSION) -lt $(ver3 $NODE_VERSION) ]
	then
		_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
	fi
}

