#!/bin/bash

#--
# Prepare rks-app. Adjust APP_DESC if _SYNTAX_HELP[$1|$1.$2] is set.
#
# global APP_DESC _SYNTAX_CMD _SYNTAX_HELP
# require _abort _syntax _merge_sh
# parameter $0 $@
#--
function _rks_app {
	local me="$1"
	test -z "$me" && _abort "call _rks_app '$0' $@"
	shift

	if ! test -z "$APP" && ! test -z "$CURR" && test -z "$APP_PID"; then
		APP="$me"
		CURR="$PWD"
		export APP_PID="$APP_PID $$"
	fi

	test -z "$APP_DESC" && _abort "APP_DESC is empty"
	test -z "${#_SYNTAX_CMD[@]}" && _abort "_SYNTAX_CMD is empty"
	test -z "${#_SYNTAX_HELP[@]}" && _abort "_SYNTAX_HELP is empty"

	[[ "$1" =	'self_update' ]] && _merge_sh

	[[ "$1" = "help" ]] && _syntax "*" "cmd:* help:*"
	test -z "$1" && return

	test -z "${_SYNTAX_HELP[$1]}" || APP_DESC="${_SYNTAX_HELP[$1]}"
	test -z "${_SYNTAX_HELP[$1.$2]}" || APP_DESC="${_SYNTAX_HELP[$1.$2]}"

	[[ ! -z "${_SYNTAX_CMD[$1]}" && "$2" = 'help' ]] && _syntax "$1" "help:"
	[[ ! -z "${_SYNTAX_CMD[$1.$2]}" && "$3" = 'help' ]] && _syntax "$1.$2" "help:"
}

