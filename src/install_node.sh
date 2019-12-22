#!/bin/bash

#--
# Install NODE_VERSION from latest binary package.
#
# @global NODE_VERSION 
# @require _abort _os_type _require_global _install_app
#--
function _install_node {

	if test -z "$NODE_VERSION"; then
		NODE_VERSION=v12.14.0
	fi

	_require_global "NODE_VERSION"

	local OS_TYPE=$(_os_type)

	if test -d /usr/local/bin && test "$OS_TYPE" = "linux"
	then
		APP_SYNC="bin include lib share"
		APP_PREFIX="/usr/local"

		local CURR_SUDO=$SUDO
		SUDO=sudo

		echo "Update node from $CURR_NODE_VERSION to $NODE_VERSION"
		_install_app "node-$NODE_VERSION-linux-x64" "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"

		SUDO=$CURR_SUDO
	else
		_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
	fi
}

