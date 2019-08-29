#!/bin/bash

#------------------------------------------------------------------------------
# Link $2 to $1
#
# @param source path
# @param link path
# @require _abort _rm _mkdir
#------------------------------------------------------------------------------
function _ln {

	if test -L "$2"; then
		local has_realpath=`which realpath`

		if ! test -z "$has_realpath"; then
  	  local link_path=`realpath "$2"`
    	local source_path=`realpath "$1"`

    	if test "$link_path" = "$source_path"; then
				echo "Link $2 to $1 already exists"
      	return
    	fi

			_rm "$2"
		else
			_rm "$2"
  	fi
	fi

	local link_dir=`dirname "$2"`
	_mkdir "$link_dir"

	echo "Link $2 to $1"
	ln -s "$1" "$2"

	if ! test -L "$2"; then
		_abort "ln -s '$1' '$2'"
	fi
}

