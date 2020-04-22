#!/bin/bash

#--
# Copy module from node_module/$2 to $1 if necessary.
# Apply patch patch/npm2js/`basename $1`.patch if found.
#
# @param target path
# @param source path (node_modules/$2)
#--
function _npm2js {
	test -z "$2" && _abort "empty module path"
	[[ -f "node_modules/$2" || -d "node_modules/$2" ]] || _abort "missing node_modules/$2"

	_cp "node_modules/$2" "$1" md5

	local base=`basename "$1"`
	if test -f "patch/npm2js/$base.patch"; then
		PATCH_LIST="$base"
		PATCH_DIR=`dirname "$1"`
		_patch patch/npm2js
	fi
}

