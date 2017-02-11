#!/bin/bash

#------------------------------------------------------------------------------
# Install npm module $1 (globally if $2 = -g)
#
# @sudo
# @param npm module name
# @param -g (optional) install globally
#------------------------------------------------------------------------------
function _npm_module {

	if test "$2" = "-g"
	then
		if test -d /usr/local/lib/node_modules/$1
		then
			echo "node module $1 is already globally installed - updating"
			sudo npm update -g $1
			return
		else
			echo "install node module $1 globally"
			sudo npm install -g $1
			return
		fi
	fi

	if test -d node_modules/$1
	then
		echo "node module $1 is already installed - updating"
		npm update $1
	return
	fi

	npm install $1 $2
}

