#!/bin/bash

#--
# Return saved value ($RKBASH_DIR/$APP/name.nfo).
#
# @param string name
# @global RKBASH_DIR
#--
function _get {
	local dir
	dir="$RKBASH_DIR"
	test "$dir" = "$HOME/.rkbash/$$" && dir="$HOME/.rkbash"
	dir="$dir/$(basename "$APP")"

	test -f "$dir/$1.nfo" || _abort "no such file $dir/$1.nfo"

	cat "$dir/$1.nfo"
}

