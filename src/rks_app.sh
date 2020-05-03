#!/bin/bash

#--
# Prepare rks-app. Adjust APP_DESC if SYNTAX_HELP[$1|$1.$2] is set.
# Execute self_update or help action if $1 = self_update|help.
#
# @global APP_DESC SYNTAX_CMD SYNTAX_HELP
# @param $0 $@
#--
function _rks_app {
	local me="$1"
	test -z "$me" && _abort "call _rks_app '$0' $*"
	shift

	if test -z "$APP"; then
		APP="$me"
		CURR="$PWD"
		export APP_PID="$APP_PID $$"
	fi

	test -z "$APP_DESC" && _abort "APP_DESC is empty"
	test -z "${#SYNTAX_CMD[@]}" && _abort "SYNTAX_CMD is empty"
	test -z "${#SYNTAX_HELP[@]}" && _abort "SYNTAX_HELP is empty"

	[[ "$1" =	'self_update' ]] && _merge_sh

	[[ "$1" = 'help' ]] && _syntax "*" "cmd:* help:*"
	test -z "$1" && return

	test -z "${SYNTAX_HELP[$1]}" || APP_DESC="${SYNTAX_HELP[$1]}"
	test -z "${SYNTAX_HELP[$1.$2]}" || APP_DESC="${SYNTAX_HELP[$1.$2]}"

	[[ ! -z "${SYNTAX_CMD[$1]}" && "$2" = 'help' ]] && _syntax "$1" "help:"
	[[ ! -z "${SYNTAX_CMD[$1.$2]}" && "$3" = 'help' ]] && _syntax "$1.$2" "help:"
}

