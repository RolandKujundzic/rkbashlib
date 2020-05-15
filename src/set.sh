#!/bin/bash

#--
# Save value as $name.nfo (in $RKSCRIPT_DIR/$APP).
#
# @param string name (required)
# @param string value
#--
function _set {
	local dir

	dir="$RKSCRIPT_DIR"
	test "$dir" = "$HOME/.rkscript/$$" && dir="$HOME/.rkscript"
	dir="$dir/$(basename "$APP")"

	test -d "$dir" || _mkdir "$dir" >/dev/null
	test -z "$1" && _abort "empty name"

	echo -e "$2" > "$dir/$1.nfo"
}

