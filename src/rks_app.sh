#!/bin/bash

#--
# Prepare rks-app.
#
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

	if [[ ! -z "$_SYNTAX_CMD[$1]" && ("$2" = '?' || "$2" = 'help') ]]; then
		test -z "${_SYNTAX_HELP[$1]}" || APP_DESC="${_SYNTAX_HELP[$1]}" 
		_syntax "$1" "help:"
	fi

	if [[ ! -z "$_SYNTAX_CMD[$1_$2]" && ("$3" = '?' || "$3" = 'help') ]]; then
		test -z "${_SYNTAX_HELP[$1_$2]}" || APP_DESC="${_SYNTAX_HELP[$1_$2]}"
		_syntax "$1_$2" "help:"
	fi
}

