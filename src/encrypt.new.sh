#!/bin/bash

#--
# Encrypt file $1 (as $1.cpt) or directory (as $1.tgz.cpt). 
# Use $RKSCRIPT_DIR/crypt.key
#
# @param file or directory path
# @param crypt key path (optional)
#--
function _encrypt {
	local FILE="$1"

	if test -d "$1"; then
		tar -czf "$1.tgz" "$1"
		FILE="$1.tgz"
	fi

	_require_file "$FILE"

	local BASE=`basename "$1"`
	local TGZ_CPT=`_get "$BASE.TGZ_CPT"`

	ccrypt -e "$1.tgz"
}

