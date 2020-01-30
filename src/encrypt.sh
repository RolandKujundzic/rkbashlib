#!/bin/bash

#--
# Encrypt file $1 (as $1.cpt) or directory (as $1.tgz.cpt). 
# Use $RKSCRIPT_DIR/crypt.key
#
# @param file or directory path
# @param crypt key path (optional)
# @require _abort
#--
function _encrypt {
	if test -d "$1"; then
		tar -czf "$1.tgz" "$1"
	elif test -f "$1"; then
		IS_DIR=0
	else
		_abort "no such file or directory [$1]"
	fi


	local BASE=`basename "$1"`
	local TGZ_CPT=`_get "$BASE.TGZ_CPT"`

	test -s "$TGZ_CPT" || _abort "no such file $TGZ_CPT"
	test -s "$1.tgz" || _abort "no such file $1.tgz"

	gunzip "$1.tgz"
	local DIFF=`tar --compare --file="$1.tar" "$1"`

	if ! test -z "$DIFF"; then
		_confirm "Update archive $TGZ_CPT" 1
		if test "$CONFIRM" = "y"; then
			tar -czf "$1.tgz" "$1"
			ccrypt -e "$1.tgz"
			_mv "$1.tgz.cpt" "$TGZ_CPT"
		fi
	fi

	_rm "$1 $1.tar"
}

