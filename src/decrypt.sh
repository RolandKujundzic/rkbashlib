#!/bin/bash

#--
# Decrypt $1. Second parameter is either empty (=ask password), password or password-file (basename starts with dot).
# If decrypted file is *.tgz archive extract it.
#
# @param encrypted file or archive
# @param password or password-file (optional, default = ask)
# @require _abort _require_program _require_file _confirm _extract_tgz _msg
#--
function _decrypt {
	test -z "$1" && _abort "_decrypt: empty filepath"
	test -s "$1" || _abort "no such file '$1'"
	_require_program ccrypt

	local TARGET=`basename "$1" | sed -E 's/\.cpt$//'`
	local PDIR=`dirname "$1"`

	if test -s "$TARGET"; then
		_confirm "Overwrite existing file $PDIR/$TARGET?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
	fi

	if ! test -z "$2"; then
		local PBASE=`basename "$2"`
		local PASS="$2"
		if test "${PBASE:0:1}" = "." && test -s "$PASS"; then
			_msg "decrypt $1 (use password from $2)"
			PASS=`cat "$2"`
		else
			_msg "decrypt $1 (use supplied password)"
		fi

		CCRYPT_PASS="$PASS" ccrypt -f -E CCRYPT_PASS -d "$1" || _abort "CCRYPT_PASS='***' ccrypt -E CCRYPT_PASS -d '$1'"
	else
		_msg "decrypt $1 - Please input password"
		ccrypt -f -d "$1" || _abort "ccrypt -d '$1'"
	fi

	_require_file "$PDIR/$TARGET"

	if test "${TARGET: -4}" = ".tgz"; then
		_extract_tgz "$PDIR/$TARGET"
		_rm "$PDIR/$TARGET" >/dev/null
	fi
}

