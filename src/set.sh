#!/bin/bash

#------------------------------------------------------------------------------
# Save value as $name.nfo (in $HOME/.rkscript/$APP).
#
# @param string name (required)
# @param string value
#------------------------------------------------------------------------------
function _set {
	local DIR="$HOME/.rkscript/"`basename "$APP"`

	test -d "$DIR" || _mkdir "$DIR"
	test -z "$1" && _abort "empty name"

	echo -e "$2" > "$DIR/$1.nfo"
}

