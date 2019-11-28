#!/bin/bash

#--
# Run lynx. Keystroke file example: "key q\nkey y"
#
# @param url
# @param keystroke file (optional)
# @require _abort _require_program
#--
function _lynx {
	_require_program lynx

	if test -z "$1"; then
		_abort "url parameter missing"
	fi

	if ! test -z "$2" && test -s "$2"; then
		lynx -cmd_script="$2" -dump "$1"
	else
		lynx -dump "$1"
	fi
}

