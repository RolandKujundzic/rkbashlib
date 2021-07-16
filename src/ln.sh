#!/bin/bash

#--
# Link $2 to $1. 
#
# @global LN_SILENT_IF_EXISTS
# @param source path
# @param link path
#--
function _ln {
	local target target_dir link_dir old_target
	_require_program realpath

	target=$(realpath "$1")
	test -z "$target" && _abort "no such directory [$1]"
	test "$2" = "$target" && _abort "ln -s '$target' '$2' # source=target"

	if test -L "$2"; then
		old_target=$(realpath "$2")

		if test "$target" = "$old_target"; then
			test -z "$LN_SILENT_IF_EXISTS" && _msg "Link $2 to $target already exists"
			return
		fi

		_rm "$2"
	fi

	link_dir=$(dirname "$2")
	link_dir=$(realpath "$link_dir")
	target_dir=$(dirname "$target")

	local tname lname cwd
	if test "$target_dir" = "$link_dir"; then
		cwd="$PWD"
		_cd "$target_dir"
		tname=$(basename "$1")
		lname=$(basename "$2")
		_msg "ln -s '$tname' '$lname' # in $PWD"
		ln -s "$tname" "$lname" || _abort "ln -s '$tname' '$lname' # in $PWD"
		_cd "$cwd"
	else
		_mkdir "$link_dir"
		_msg "Link $2 to $target"
		ln -s "$target" "$2"
	fi

	if ! test -L "$2"; then
		_abort "ln -s '$target' '$2'"
	fi
}

