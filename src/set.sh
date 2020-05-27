#!/bin/bash

#--
# Save value as $name.nfo (in $RKBASH_DIR/$APP).
#
# @param string name (required)
# @param string value
# @global RKBASH_DIR
#--
function _set {
	local dir

	dir="$RKBASH_DIR"
	test "$dir" = "$HOME/.rkbash/$$" && dir="$HOME/.rkbash"
	dir="$dir/$(basename "$APP")"

	test -d "$dir" || _mkdir "$dir" >/dev/null
	test -z "$1" && _abort "empty name"

	echo -e "$2" > "$dir/$1.nfo"
}

