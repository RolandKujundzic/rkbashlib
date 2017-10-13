#!/bin/bash

#------------------------------------------------------------------------------
# Copy module from node_module/$2 to $1 if necessary.
# Apply patch patch/npm2js/`basename $1`.patch if found.
#
# @param target path
# @param source path (node_modules/$2)
# @require _abort _cp _patch
#------------------------------------------------------------------------------
function _npm2js {

	if test -z "$2"; then
		_abort "empty module path"
	fi

	if ! test -f "node_modules/$2" && ! test -d "node_modules/$2"; then
		_abort "missing node_modules/$2"
	fi

	_cp "node_modules/$2" "$1" md5

	local BASE=`basename "$1"`
	local PATCH="$BASE"".patch"

	if test -f patch/npm2js/$PATCH; then
		PATCH_LIST="$BASE"
		PATCH_DIR=`dirname "$1"`
		_patch patch/npm2js
	fi
}

