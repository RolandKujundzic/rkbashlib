#!/bin/bash

#--
# Return saved value ($RKSCRIPT_DIR/$APP/name.nfo).
#
# @param string name
#--
function _get {
	local DIR="$RKSCRIPT_DIR"
	test "$DIR" = "$HOME/.rkscript/$$" && DIR="$HOME/.rkscript"
	DIR="$DIR/"`basename "$APP"`

	test -f "$DIR/$1.nfo" || _abort "no such file $DIR/$1.nfo"

	cat "$DIR/$1.nfo"
}

