#!/bin/bash

#--
# Install node NODE_VERSION from latest binary package. 
# To instal latest use _node_current instead.
#
# @global NODE_VERSION
# @param remove (optional)
# shellcheck disable=SC2034
#--
function _install_node {
	local a os_type curr_sudo

	os_type=$(_os_type)
	test "$os_type" = "linux" || _abort "Update node to version >= $NODE_VERSION - see https://nodejs.org/"

	if test "$1" == 'remove'; then
		for a in '/usr/local/bin/npm' '/usr/local/bin/node'; do
			_rm "$a"
		done

		return
	fi

	_require_global NODE_VERSION
	_msg "Install node $NODE_VERSION"
	APP_SYNC="bin include lib share"
	APP_PREFIX="/usr/local"

	curr_sudo=$SUDO
	SUDO=sudo
	_install_app "node-$NODE_VERSION-linux-x64" "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"
	SUDO=$curr_sudo
}

