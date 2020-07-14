#!/bin/bash

#--
# Run lynx. Keystroke file example: "key q\nkey y"
#
# @param url
# @param keystroke file (optional)
#--
function _lynx {
	_require_program lynx

	if test -z "$1"; then
		_abort "url parameter missing"
	fi

	if [[ -n "$2" && -s "$2" ]]; then
		lynx -cmd_script="$2" -dump "$1"
	else
		lynx -dump "$1"
	fi
}

