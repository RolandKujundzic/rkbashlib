#!/bin/bash

#--
# Download URL with wget. 
#
# @param url
# @param save as default = autodect, use "-" for stdout
#--
function _wget {
	test -z "$1" && _abort "empty url"
	_require_program wget

	local SAVE_AS=${2:-`basename "$1"`}
	if test -s "$SAVE_AS"; then
		_confirm "Overwrite $SAVE_AS" 1
		if test "$CONFIRM" != "y"; then
			echo "keep $SAVE_AS - skip wget '$1'"
			return
		fi
	fi

	if test -z "$2"; then
		echo "download $1"
		wget -q "$1" || _abort "wget -q '$1'"
	elif test "$2" = "-"; then
		wget -q -O "$2" "$1" || _abort "wget -q -O '$2' '$1'"
		return
	else
		echo "download $1 as $2"
		wget -q -O "$2" "$1" || _abort "wget -q -O '$2' '$1'"
	fi

	if test -z "$2"; then
		if ! test -s "$SAVE_AS"; then
			local NEW_FILES=`find . -amin 1 -type f`
			test -z "$NEW_FILES" && _abort "Download from $1 failed"
		fi
	elif ! test -s "$2"; then
		_abort "Download of $2 from $1 failed"
	fi
}

