#!/bin/bash

#--
# Encrypt file $1 (as $1.cpt) or directory (as $1.tgz.cpt). Remove source. 
# Second parameter is either empty (=ask password), password or password-file (basename must start with dot).
#
# @param file or directory path
# @param crypt key path (optional)
#--
function _encrypt {
	test -z "$1" && _abort "_encrypt: first parameter (path/to/source) missing"
	_require_program ccrypt

	local src pass base
	src="$1"
	pass="$2"
	base=$(basename "$2")

	if test -d "$1"; then
		src="$1.tgz"
		_create_tgz "$src" "$1"
	fi

	test -s "$src" || _abort "_encrypt: no such file [$src]"
	test -z "$(echo "$1" | grep -E '\.cpt$')" || _abort "$src has already suffix .cpt"
	
	if test -s "$src.cpt"; then
		_confirm "Overwrite existing $src.cpt?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
	fi

	if ! test -z "$pass"; then
		if test "${base:0:1}" = "." && test -s "$2"; then
			_msg "encrypt '$src' as *.cpt (use password from '$2')"
			pass=$(cat "$2")
		else
			_msg "encrypt '$src' as *.cpt (use supplied password)"
		fi

		CCRYPT_PASS="$pass" ccrypt -f -E CCRYPT_PASS -e "$src" || _abort "CCRYPT_PASS='***' ccrypt -E CCRYPT_PASS -e '$src'"
	else
		_msg "encrypt '$src' as *.cpt - Please input password"
		ccrypt -f -e "$src" || _abort "ccrypt -e '$src'"
	fi

	test -s "$src.cpt" || _abort "no such file $src.cpt"

	_rm "$src" >/dev/null
	if test -d "$1"; then
		_confirm "Remove source directory $1?" 1
		test "$CONFIRM" = "y" && _rm "$1" >/dev/null
	fi
}

