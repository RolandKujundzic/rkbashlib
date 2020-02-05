#!/bin/bash

#--
# Save value as $name.nfo (in $RKSCRIPT_DIR/$APP).
#
# @param string name (required)
# @param string value
#--
function _set {
	local DIR="$RKSCRIPT_DIR"
	test "$DIR" = "$HOME/.rkscript/$$" && DIR="$HOME/.rkscript"
	DIR="$DIR/"`basename "$APP"`

	test -d "$DIR" || _mkdir "$DIR" >/dev/null
	test -z "$1" && _abort "empty name"

	echo -e "$2" > "$DIR/$1.nfo"
}

