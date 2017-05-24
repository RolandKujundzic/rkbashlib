#!/bin/bash

#------------------------------------------------------------------------------
# Check node.js version. Update to NPM_VERSION
#
# @global NODE_VERSION NPM_VERSION APP_PREFIX APP_FILE_LIST APP_DIR_LIST
# @require ver3 abort require_global install_app mkdir cp dl_unpack md5 os_type
#------------------------------------------------------------------------------
function _node_version {
	_require_global "NODE_VERSION NPM_VERSION"

	local CURR_NODE_VERSION=`node --version`
	if [ $(_ver3 $CURR_NODE_VERSION) -lt $(_ver3 $NODE_VERSION) ]
	then
		local OS_TYPE=$(_os_type)

		if test -f /usr/local/bin && test "$OS_TYPE" = "linux"
		then
			APP_FILE_LIST="bin/npm bin/node share/man/man1/node.1 share/systemtap/tapset/node.stp"
			APP_DIR_LIST="include/node lib/node_modules share/doc/node"

			if test -z "$CURR_NODE_VERSION" && test -f /usr/local/bin/node; then
				APP_PREFIX="/opt/node_$CURR_NODE_VERSION"
				echo "backup current node version to $APP_PREFIX"
				_install_app .
			if

			APP_PREFIX="/usr/local"
			_install_app "node-$NODE_VERSION-linux-x64" "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz"
		else
			_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
		fi
	fi

	local CURR_NPM_VERSION=`npm --version`
	if [ $(_ver3 $CURR_NPM_VERSION) -lt $(_ver3 $NPM_VERSION) ]
	then
		echo -e "Update npm from $CURR_NPM_VERSION to latest\nType in sudo password if necessary"
		sudo npm install npm@latest -g
		sudo npm update --depth=0 -g
	fi
}

