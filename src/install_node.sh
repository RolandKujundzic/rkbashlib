#!/bin/bash

#------------------------------------------------------------------------------
# Install NODE_VERSION from latest binary package.
#
# @global NODE_VERSION 
# @require abort os_type require_global install_app
#------------------------------------------------------------------------------
function _install_node {

  if test -z "$NODE_VERSION"; then
    NODE_VERSION=v6.11.4
  fi

	_require_global "NODE_VERSION"

	local OS_TYPE=$(_os_type)

	if test -d /usr/local/bin && test "$OS_TYPE" = "linux"
	then
		APP_FILE_LIST="bin/npm bin/node share/man/man1/node.1 share/systemtap/tapset/node.stp"
		APP_DIR_LIST="include/node lib/node_modules share/doc/node"
		APP_PREFIX="/usr/local"

		local CURR_SUDO=$SUDO
	  SUDO=sudo

		echo -e "Update node from $CURR_NODE_VERSION to $NODE_VERSION"
		_install_app "node-$NODE_VERSION-linux-x64" "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"

		SUDO=$CURR_SUDO
	else
		_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
	fi
}

