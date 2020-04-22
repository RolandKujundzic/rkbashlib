#!/bin/bash

#--
# Link $2 to $1.
#
# @param source path
# @param link path
#--
function _ln {
	_require_program realpath

	local target=`realpath "$1"`
	test -z "$target" && _abort "no such directory [$1]"
	test "$2" = "$target" && _abort "ln -s '$target' '$2' # source=target"

	if test -L "$2"; then
		local old_target=`realpath "$2"`

		if test "$target" = "$old_target"; then
			echo "Link $2 to $target already exists"
			return
		fi

		_rm "$2"
	fi

	local link_dir=`dirname "$2"`
	link_dir=`realpath "$link_dir"`
	local target_dir=`dirname "$target"`

	if test "$target_dir" = "$link_dir"; then
		local cwd="$PWD"
		_cd "$target_dir"
		local tname=`basename "$1"`
		local lname=`basename "$2"`
		echo "ln -s '$tname' '$lname' # in $PWD"
		ln -s "$tname" "$lname" || _abort "ln -s '$tname' '$lname' # in $PWD"
		_cd "$cwd"
	else
		_mkdir "$link_dir"
		echo "Link $2 to $target"
		ln -s "$target" "$2"
	fi

	if ! test -L "$2"; then
		_abort "ln -s '$target' '$2'"
	fi
}

