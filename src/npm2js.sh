#!/bin/bash

#------------------------------------------------------------------------------
# Copy module from node_module/$2 to $1 if necessary
#
# @param target path
# @param node_modules/$2 (source path)
# @require abort, cp
#------------------------------------------------------------------------------
function _npm2js {

	if test -z "$2"; then
		_abort "empty module path"
	fi

	if ! test -f "node_modules/$2" && ! test -d "node_modules/$2"; then
		_abort "missing node_modules/$2"
	fi

	_cp "node_modules/$2" "$1" md5
}

