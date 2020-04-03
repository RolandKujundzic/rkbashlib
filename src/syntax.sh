#!/bin/bash

declare -A _SYNTAX_CMD
declare -A _SYNTAX_HELP

#--
# Abort with SYNTAX: message. Usually APP=$0.
# If $1 = "*" show join('|', ${!_SYNTAX_CMD[@]}).
# If APP_DESC(_2|_3|_4) is set output APP_DESC\n\n(APP_DESC_2\n\n ...).
#
# @export _SYNTAX_CMD _SYNTAX_HELP
# @global APP APP_DESC APP_DESC_2 APP_DESC_3 APP_DESC_4 $APP_PREFIX 
# @param message
# @param info (e.g. cmd:* = show all _SYNTAX_CMD otherwise show cmd|help:name = _SYNTAX_CMD|_SYNTAX_HELP[name])
#--
function _syntax {
	local MSG="$1\n"
	local a; local b; local prefix; local i;

	if ! test -z "${_SYNTAX_CMD[$1]}"; then
		MSG="${_SYNTAX_CMD[$1]}\n"
	elif test "${1: -1}" = "*" && test "${#_SYNTAX_CMD[@]}" -gt 0; then
		test "$1" = "*" && a='^[a-zA-Z0-9_]+$' || { prefix="${1:0:-1}"; a="^${1:0:-2}"'\.[a-zA-Z0-9_\.]+$'; }
		local KEYS="${!_SYNTAX_CMD[@]}"
		MSG=

		for b in $KEYS; do
			grep -E "$a" >/dev/null <<< "$b" && MSG="$MSG|${b/$prefix/}"
		done

		MSG="${MSG:1}\n"
	fi

	for a in $2; do
		local OLD_MSG="$MSG"

		if test "${a:0:4}" = "cmd:"; then
			test "$a" = "cmd:" && a="cmd:$1"
			test "${a:4}" = "*" && a='^[a-zA-Z0-9_]+$' || a="^${a:4:-2}"'\.[a-zA-Z0-9_]+$'
			for b in ${!_SYNTAX_CMD[@]}; do
				grep -E "$a" >/dev/null <<< "$b" && MSG="$MSG\n$APP ${_SYNTAX_CMD[$b]}"
			done
		elif test "${a:0:5}" = "help:"; then
			test "$a" = "help:" && a="help:$1"
			test "${a:5}" = "*" && a='^[a-zA-Z0-9_]+$' || a="^${a:5:-2}"'\.[a-zA-Z0-9_\.]+$'

			for b in ${!_SYNTAX_HELP[@]}; do
				if test "$b" = "$1"; then
					MSG="$MSG\n${_SYNTAX_HELP[$b]}"
				elif grep -E "$a" >/dev/null <<< "$b"; then
					prefix=`sed -E 's/^[a-zA-Z0-9_]+\.//' <<< $b`
					MSG="$MSG\n"`printf "%12s: ${_SYNTAX_HELP[$b]}" $prefix`
				fi
			done
		fi

		test "$OLD_MSG" != "$MSG" && MSG="$MSG\n"
	done

	if ! test -z "$APP_PREFIX"; then
		echo -e "\nSYNTAX: $APP_PREFIX $APP $MSG" 1>&2
	else
		echo -e "\nSYNTAX: $APP $MSG" 1>&2
	fi

	local DESC=""
	for a in APP_DESC APP_DESC_2 APP_DESC_3 APP_DESC_4; do
		test -z "${!a}" || DESC="$DESC${!a}\n\n"
	done
	echo -e "$DESC" 1>&2

	exit 1
}

