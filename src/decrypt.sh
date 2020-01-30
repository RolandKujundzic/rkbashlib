#!/bin/bash

#--
# Open encrypted path/to/ARCHIVE.tgz.cpt as ./ARCHIVE.
#
# @param file
#--
function _decrypt {
	local BASE=`basename "$1"`
	local DIR=`dirname "$1"`

	BASE=`echo "$BASE" | sed -E 's/\.tgz\.cpt$//'`

	_set "$BASE.TGZ_CPT" "$1"

	if test -z "$1" || ! test -s "$DIR/$BASE.tgz.cpt"; then
		_syntax "open path/to/archive.tgz.cpt"
	fi

	if test -d "$BASE"; then
		_confirm "Remove $BASE"
		test "$CONFIRM" = "y" || return
		_rm "$BASE"
	fi

	_cp "$1" "_$BASE.tgz.cpt" 
	ccrypt -d "_$BASE.tgz.cpt"
	_mv "_$BASE.tgz" "$BASE.tgz"
	tar -xzf "$BASE.tgz"
}

