#!/bin/bash

#--
# Install npm module $1 (globally if $2 = -g)
#
# @sudo
# @param package_name
# @param npm_param (e.g. -g, --save-dev)
# shellcheck disable=SC2086
#--
function _npm_module {
	if ! command -v npm >/dev/null; then
		_node_current
  fi

	local extra_param
	extra_param="$2"
	test "$1" = "ios-deploy" && extra_param="$2 --unsafe-perm=true --allow-root"

	if test "$2" = "-g"; then
		if test -d "/usr/local/lib/node_modules/$1"; then
			_msg "node module $1 is already globally installed - updating"
			sudo npm update $extra_param "$1"
			return
		else
			_msg "install node module $1 globally"
			sudo npm install $extra_param "$1"
			return
		fi
	fi

	if test -d "node_modules/$1"; then
		_msg "node module $1 is already installed - updating"
		npm update $extra_param "$1" >/dev/null
	else
		test -z "$extra_param" && extra_param='--save'
		_msg "install node module $1"
		npm install $extra_param "$1"
	fi
}

