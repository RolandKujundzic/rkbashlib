#!/bin/bash

declare -A SYNTAX_CMD
declare -A SYNTAX_HELP

#--
# Abort with SYNTAX: message. Usually APP=$0.
# If $1 = "*" show join('|', ${!SYNTAX_CMD[@]}).
# If APP_DESC(_2|_3|_4) is set output APP_DESC\n\n(APP_DESC_2\n\n ...).
#
# @declare SYNTAX_CMD SYNTAX_HELP
# @global SYNTAX_CMD SYNTAX_HELP APP APP_DESC APP_DESC_2 APP_DESC_3 APP_DESC_4 $APP_PREFIX 
# @param message
# @param info (e.g. cmd:* = show all SYNTAX_CMD otherwise show cmd|help:[name] = SYNTAX_CMD|SYNTAX_HELP[name])
#--
function _syntax {
	local a msg old_msg desc base
	msg=$(_syntax_cmd "$1") 

	for a in $2; do
		old_msg="$msg"

		if test "${a:0:4}" = "cmd:"; then
			test "$a" = "cmd:" && a="cmd:$1"
			msg="$msg$(_syntax_cmd_other "$a")"
		elif test "${a:0:5}" = "help:"; then
			test "$a" = "help:" && a="help:$1"
			msg="$msg$(_syntax_help "${a:5}")"
		fi

		test "$old_msg" != "$msg" && msg="$msg\n"
	done

	test "${msg: -3:1}" = '|' && msg="${msg:0:-3}\n"

	base=$(basename "$APP")
	if test -n "$APP_PREFIX"; then
		echo -e "\nSYNTAX: $APP_PREFIX $base $msg" 1>&2
	else
		echo -e "\nSYNTAX: $base $msg" 1>&2
	fi

	for a in APP_DESC APP_DESC_2 APP_DESC_3 APP_DESC_4; do
		test -z "${!a}" || desc="$desc${!a}\n\n"
	done
	echo -e "$desc" 1>&2

	exit 1
}


#--
# Return SYNTAX_CMD
# @param syntax message
#--
function _syntax_cmd {
	local a rx msg keys prefix
	keys=$(_sort "${!SYNTAX_CMD[@]}")
	msg="$1\n" 

	if test -n "${SYNTAX_CMD[$1]}"; then
		msg="${SYNTAX_CMD[$1]}\n"
	elif test "${1: -1}" = "*" && test "${#SYNTAX_CMD[@]}" -gt 0; then
		if test "$1" = "*"; then
			rx='^[a-zA-Z0-9_]+$'
		else
			prefix="${1:0:-1}"
			rx="^${1:0:-2}"'\.[a-zA-Z0-9_\.]+$'
		fi

		msg=
		for a in $keys; do
			grep -E "$rx" >/dev/null <<< "$a" && msg="$msg|${a/$prefix/}"
		done
		msg="${msg:1}\n"
	elif [[ "$1" = *'.'* && -n "${SYNTAX_CMD[${1%%.*}]}" ]]; then
		msg="${SYNTAX_CMD[${1%%.*}]}\n"
	fi

	echo "$msg"
}


#--
# Return additional SYNTAX_CMD information
# @param 
#--
function _syntax_cmd_other {
	local a rx msg keys base
	keys=$(_sort "${!SYNTAX_CMD[@]}")
	rx="$1"

	test "${rx:4}" = "*" && rx='^[a-zA-Z0-9_]+$' || rx="^${rx:4:-2}"'\.[a-zA-Z0-9_]+$'

	base=$(basename "$APP")
	for a in $keys; do
		grep -E "$rx" >/dev/null <<< "$a" && msg="$msg\n$base ${SYNTAX_CMD[$a]}"
	done

	echo "$msg"
}


#--
# Return SYNTAX_HELP information
# @param 
#--
function _syntax_help {
	local a rx msg keys prefix
	keys=$(_sort "${!SYNTAX_HELP[@]}")

	if test "$1" = '*'; then
		rx='^[a-zA-Z0-9_]+$'
	elif test "${1: -1}" = '*'; then
		rx="^${rx: -2}"'\.[a-zA-Z0-9_\.]+$'
	fi

	for a in $keys; do
		if test "$a" = "$1"; then
			msg="$msg\n${SYNTAX_HELP[$a]}"
		elif test -n "$rx" && grep -E "$rx" >/dev/null <<< "$a"; then
			prefix=$(sed -E 's/^[a-zA-Z0-9_]+\.//' <<< "$a")
			msg="$msg\n$prefix: ${SYNTAX_HELP[$a]}\n"
		fi
	done

	[[ -n "$msg" && "$msg" != "\n$APP_DESC" ]] && echo -e "$msg"
}

