#!/bin/bash

#------------------------------------------------------------------------------
# Link $2 to $1
#
# @param source path
# @param link path
# @require _abort _rm _mkdir _require_program
#------------------------------------------------------------------------------
function _ln {
	_require_program realpath

	local target=`realpath "$1"`

	if test "$PWD" = "$target"; then
		_abort "ln -s '$taget' '$2' # in $PWD"
	fi

	if test -L "$2"; then
		local old_target=`realpath "$2"`

		if test "$target" = "$old_target"; then
			echo "Link $2 to $target already exists"
			return
		fi

		_rm "$2"
	fi

	local link_dir=`dirname "$2"`
	_mkdir "$link_dir"

	echo "Link $2 to $target"
	ln -s "$target" "$2"

	if ! test -L "$2"; then
		_abort "ln -s '$target' '$2'"
	fi
}

