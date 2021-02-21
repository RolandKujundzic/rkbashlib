#!/bin/bash

#--
# Prepare rks-app. Adjust APP_DESC if SYNTAX_HELP[$1|$1.$2] is set.
# Execute self_update if $1 = self_update.
# Show help if last parameter is help or --help is set.
#
# @example APP_DESC='...'; _rks_app "$@"
# @global APP_DESC SYNTAX_CMD SYNTAX_HELP
# @export APP CURR APP_DIR APP_PID (if not set)
# @param $@
# shellcheck disable=SC2034,SC2119
#--
function _rks_app {
	_parse_arg "$@"

	local me p1 p2 p3
	me="$0"
	p1="$1"
	p2="$2"
	p3="$3"

	test -z "$me" && _abort 'call _rks_app "$@"'
	test -z "${ARG[1]}" || p1="${ARG[1]}"
	test -z "${ARG[2]}" || p2="${ARG[2]}"
	test -z "${ARG[3]}" || p3="${ARG[3]}"

	if test -z "$APP"; then
		APP="$me"
		APP_DIR=$( cd "$( dirname "$APP" )" >/dev/null 2>&1 && pwd )
		CURR="$PWD"
		if test -z "$APP_PID"; then
			 export APP_PID="$$"
		elif test "$APP_PID" != "$$"; then
			 export APP_PID="$APP_PID $$"
		fi
	fi

	test -z "$APP_DIR" &&
		APP_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)

	test -z "${#SYNTAX_CMD[@]}" && _abort "SYNTAX_CMD is empty"
	test -z "${#SYNTAX_HELP[@]}" && _abort "SYNTAX_HELP is empty"

	[[ "$p1" =	'self_update' ]] && _merge_sh

	[[ "$p1" = 'help' ]] && _syntax "*" "cmd:* help:*"
	test -z "$p1" && return

	test -n "${SYNTAX_HELP[$p1]}" && APP_DESC="${SYNTAX_HELP[$p1]}"
	[[ -n "$p2" && -n "${SYNTAX_HELP[$p1.$p2]}" ]] && APP_DESC="${SYNTAX_HELP[$p1.$p2]}"

	[[ -n "$p2" && -n "${SYNTAX_CMD[$p1.$p2]}" && ("$p3" = 'help' || "${ARG[help]}" = '1') ]] && \
		_syntax "$p1.$p2" "help:"

	[[ -n "${SYNTAX_CMD[$p1]}" && ("$p2" = 'help' || "${ARG[help]}" = '1') ]] && \
		_syntax "$p1" "help:"

	test "${ARG[help]}" = '1' && _syntax "*" "cmd:* help:*"
}

