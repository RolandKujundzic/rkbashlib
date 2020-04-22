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

	local SRC="$1"
	local PASS="$2"

	if test -d "$1"; then
		SRC="$1.tgz"
		_create_tgz "$SRC" "$1"
	fi

	test -s "$SRC" || _abort "_encrypt: no such file [$SRC]"

	local IS_CPT_FILE=`echo "$1" | grep -E '\.cpt$'`
	test -z "$IS_CPT_FILE" || _abort "$SRC has already suffix .cpt"
	
	if test -s "$SRC.cpt"; then
		_confirm "Overwrite existing $SRC.cpt?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
	fi

	if ! test -z "$PASS"; then
		local BASE=`basename "$2"`
		if test "${BASE:0:1}" = "." && test -s "$2"; then
			_msg "encrypt '$SRC' as *.cpt (use password from '$2')"
			PASS=`cat "$2"`
		else
			_msg "encrypt '$SRC' as *.cpt (use supplied password)"
		fi

		CCRYPT_PASS="$PASS" ccrypt -f -E CCRYPT_PASS -e "$SRC" || _abort "CCRYPT_PASS='***' ccrypt -E CCRYPT_PASS -e '$SRC'"
	else
		_msg "encrypt '$SRC' as *.cpt - Please input password"
		ccrypt -f -e "$SRC" || _abort "ccrypt -e '$SRC'"
	fi

	test -s "$SRC.cpt" || _abort "no such file $SRC.cpt"

	_rm "$SRC" >/dev/null
	if test -d "$1"; then
		_confirm "Remove source directory $1?" 1
		test "$CONFIRM" = "y" && _rm "$1" >/dev/null
	fi
}

