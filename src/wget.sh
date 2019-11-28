#!/bin/bash

#--
# Download URL with wget. 
#
# @param url
# @param save as default = autodect, use "-" for stdout
# @require _abort _require_program _confirm
#--
function _wget {
	if test -z "$1"; then
		_abort "empty url"
	fi

	_require_program wget

	if ! test -z "$2" && test "$2" != "-" && test -f "$2"; then
		_confirm "Overwrite $2" 1
		if test "$CONFIRM" != "y"; then
			echo "keep $2 - skip wget '$1'"
			return
		fi
	fi

	if test -z "$2"; then
		echo "download $1"
		wget -q "$1"
	elif test "$2" = "-"; then
		wget -q -O "$2" "$1"
	else
		echo "download $1 as $2"
		wget -q -O "$2" "$1"
	fi

  if test "$2" != "-"; then
		if test -z "$2"; then
			local SAVE_AS=`basename "$1"`
			local NEW_FILES=`find . -amin 1 -type f`

			if ! test -s "$SAVE_AS" && test -z "$NEW_FILES"; then
				_abort "Download from $1 failed"
			fi
		elif ! test -s "$2"; then
			_abort "Download of $2 from $1 failed"
		fi
  fi
}

