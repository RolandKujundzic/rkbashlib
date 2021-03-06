#!/bin/bash

#--
# Download URL with wget. Autocreate target path.
# Use WGET_KEEP to keep existing files.
# Use WGET_SHA256 for sha256sum check.
#
# @param url
# @global WGET_KEEP WGET_SHA256
# @param save as default = autodect, use "-" for stdout
#--
function _wget {
	local save_as

	test -z "$1" && _abort "empty url"
	_require_program wget

	save_as=${2:-$(basename "$1")}
	if test -s "$save_as"; then
		_sha256 "$save_as" "$WGET_SHA256"
		if test "$WGET_KEEP" = '1'; then
			_msg "keep existing $save_as"
			return
		fi

		_confirm "Overwrite $save_as" 1
		if test "$CONFIRM" != "y"; then
			_msg "keep $save_as - skip wget '$1'"
			return
		fi
	fi

	if test -z "$2"; then
		_msg "download $1"
		wget -q "$1" || _abort "wget -q '$1'"
	elif test "$2" = "-"; then
		wget -q -O "$2" "$1" || _abort "wget -q -O '$2' '$1'"
		return
	else
		_mkdir "$(dirname "$2")"
		_msg "download $1 to $2"
		wget -q -O "$2" "$1" || _abort "wget -q -O '$2' '$1'"
	fi

	local new_files
	if test -z "$2"; then
		if ! test -s "$save_as"; then
			new_files=$(find . -amin 1 -type f)
			test -z "$new_files" && _abort "Download $1 failed"
		fi
	elif ! test -s "$2"; then
		_abort "Download $2 to $1 failed"
	fi

	_sha256 "$save_as" "$WGET_SHA256"
}

