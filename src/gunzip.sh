#!/bin/bash

#--
# Gunzip file.
#
# @param file
# @param ignore_if_not_gzip (optional)
#--
function _gunzip {
	test -f "$1" || _abort "no such gzip file [$1]"
	if test -z "$(file "$(realpath "$1")"  | grep 'gzip compressed data')"; then
		if test -z "$2"; then
			_abort "invalid gzip file [$1]"
		else 
			echo "$1 is not in gzip format - skip gunzip"
			return
		fi
	fi

	local target
	target="${1%*.gz}"

	if test -L "$1"; then
		echo "gunzip -c '$1' > '$target'"
		gunzip -c "$1" > "$target"
	else
		echo "gunzip $1"
		gunzip "$1"
	fi

	if ! test -f "$target"; then
		_abort "gunzip failed - no such file $target"
	fi
}

