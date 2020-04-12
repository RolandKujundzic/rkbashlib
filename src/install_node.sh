#!/bin/bash

#--
# Install node NODE_VERSION from latest binary package. 
# If you want to install|update node/npm use _node_version instead.
#
# @see _node_version
# @global NODE_VERSION
# @require _abort _require_global _msg _os_type _install_app
#--
function _install_node {
	_require_global "NODE_VERSION"
	local os_type=$(_os_type)
	test "$os_type" = "linux" || _abort "Update node to version >= $NODE_VERSION - see https://nodejs.org/"

	_msg "Install node $NODE_VERSION"
	APP_SYNC="bin include lib share"
	APP_PREFIX="/usr/local"

	local curr_sudo=$SUDO
	SUDO=sudo
	_install_app "node-$NODE_VERSION-linux-x64" "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"
	SUDO=$curr_sudo
}

