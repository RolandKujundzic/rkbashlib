#!/bin/bash

#------------------------------------------------------------------------------
# Check node.js version. Update to NODE_VERSION and NPM_VERSION if necessary.
# Use NODE_VERSION=v6.11.0 and NPM_VERSION=5.0.3 ad default.
#
# @global NODE_VERSION NPM_VERSION APP_PREFIX APP_FILE_LIST APP_DIR_LIST
# @require ver3 abort require_global install_app mkdir cp dl_unpack md5 
# @require sudo rm mv os_type
#------------------------------------------------------------------------------
function _node_version {

	if test -z "$NODE_VERSION"; then
		NODE_VERSION=v6.11.0
	fi

	if test -z "$NPM_VERSION"; then
		NPM_VERSION=5.0.3
	fi

	_require_global "NODE_VERSION NPM_VERSION"

	local CURR_NODE_VERSION=`node --version`
	if [ $(_ver3 $CURR_NODE_VERSION) -lt $(_ver3 $NODE_VERSION) ]
	then
		local OS_TYPE=$(_os_type)

		if test -d /usr/local/bin && test "$OS_TYPE" = "linux"
		then
			APP_FILE_LIST="bin/npm bin/node share/man/man1/node.1 share/systemtap/tapset/node.stp"
			APP_DIR_LIST="include/node lib/node_modules share/doc/node"
			APP_PREFIX="/usr/local"
			echo -e "Update node from $CURR_NODE_VERSION to $NODE_VERSION"
			_sudo "_install_app 'node-$NODE_VERSION-linux-x64' 'https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz'"
		else
			_abort "Update node.js to version >= $NODE_VERSION - see https://nodejs.org/"
		fi
	fi

	local CURR_NPM_VERSION=`npm --version`
	if [ $(_ver3 $CURR_NPM_VERSION) -lt $(_ver3 $NPM_VERSION) ]
	then
		echo -e "Update npm from $CURR_NPM_VERSION to latest"
		_sudo "npm i -g npm"
		# sudo npm install npm@latest -g
		# sudo npm update --depth=0 -g
		# sudo chown -R $USER:$(id -gn $USER) /home/$USER/.config
	fi
}

