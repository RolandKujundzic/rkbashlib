#!/bin/bash

#--
# Decrypt $1. Second parameter is either empty (=ask password), password or password-file (basename starts with dot).
# If decrypted file is *.tgz archive extract it.
#
# @param encrypted file or archive
# @param password or password-file (optional, default = ask)
#--
function _decrypt {
	test -z "$1" && _abort "_decrypt: empty filepath"
	test -s "$1" || _abort "no such file '$1'"
	_require_program ccrypt

	local target pdir pbase pfile pass
	target=$(basename "$1" | sed -E 's/\.cpt$//')
	pdir=$(dirname "$1")

	if test -s "$target"; then
		_confirm "Overwrite existing file $pdir/$target?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
	fi

	if test -n "$2"; then
		pfile="$2"
		pbase=$(basename "$pfile")
		if test "${pbase:0:1}" = "." && test -s "$pfile"; then
			_msg "decrypt $1 (use password from $pfile)"
			pass=$(cat "$pfile")
		else
			_msg "decrypt $1 (use supplied password)"
		fi

		CCRYPT_PASS="$pass" ccrypt -f -E CCRYPT_PASS -d "$1" || _abort "CCRYPT_PASS='***' ccrypt -E CCRYPT_PASS -d '$1'"
	else
		_msg "decrypt $1 - Please input password"
		ccrypt -f -d "$1" || _abort "ccrypt -d '$1'"
	fi

	_require_file "$pdir/$target"

	if test "${target: -4}" = ".tgz"; then
		_extract_tgz "$pdir/$target"
		_rm "$pdir/$target" >/dev/null
	fi
}

