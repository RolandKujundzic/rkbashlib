#!/bin/bash

#------------------------------------------------------------------------------
# Return saved value ($HOME/.rkscript/$APP/name.nfo).
#
# @param string name
#------------------------------------------------------------------------------
function _get {
	local DIR="$HOME/.rkscript/"`basename "$APP"`

	test -f "$DIR/$1.nfo" || _abort "no such file $DIR/$1.nfo"

	cat "$DIR/$1.nfo"
}

