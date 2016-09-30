#!/bin/bash

#------------------------------------------------------------------------------
# Copy $1 to $2
#
# @param source path
# @param target path
# @param [md5] if set make md5 file comparison
# @require abort
#------------------------------------------------------------------------------
function _cp {

	local TARGET=`dirname "$2"`

	if ! test -d "$TARGET"; then
		_abort "no such directory [$TARGET]"
	fi

	if test "$3" = "md5" && test -f "$1" && test -f "$2"; then
	  local MD1=`md5 -q "$1"`
		local MD2=`md5 -q "$2"`

		if test "$MD1" = "$MD2"; then
			echo "Do not overwrite $1 with $2 (same content)"
		else
			echo "Copy file $1 to $2 (update)"
			cp "$1" "$2" || _abort "cp '$1' '$2'"
		fi

		return
  fi

  if test -f "$1"; then
    echo "Copy file $1 to $2"
		cp "$1" "$2" || _abort "cp '$1' '$2'"
	elif test -d "$1"; then
		echo "Copy directory $1 to $2"
		cp -r "$1" "$2" || _abort "cp -r '$1' '$2'"
	else
		_abort "No such file or directory [$1]"
  fi
}

