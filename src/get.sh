#!/bin/bash

#--
# Return saved value ($RKSCRIPT_DIR/$APP/name.nfo).
#
# @param string name
#--
function _get {
	local dir
	dir="$RKSCRIPT_DIR"
	test "$dir" = "$HOME/.rkscript/$$" && dir="$HOME/.rkscript"
	dir="$dir/$(basename "$APP")"

	test -f "$dir/$1.nfo" || _abort "no such file $dir/$1.nfo"

	cat "$dir/$1.nfo"
}

