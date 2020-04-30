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
	local msg="$1\n" 
	local a b prefix
	local keys=`_sort ${!SYNTAX_CMD[@]}`

	if ! test -z "${SYNTAX_CMD[$1]}"; then
		msg="${SYNTAX_CMD[$1]}\n"
	elif test "${1: -1}" = "*" && test "${#SYNTAX_CMD[@]}" -gt 0; then
		test "$1" = "*" && a='^[a-zA-Z0-9_]+$' || { prefix="${1:0:-1}"; a="^${1:0:-2}"'\.[a-zA-Z0-9_\.]+$'; }

		msg=
		for b in $keys; do
			grep -E "$a" >/dev/null <<< "$b" && msg="$msg|${b/$prefix/}"
		done
		msg="${msg:1}\n"
	elif [[ "$1" = *'.'* && ! -z "${SYNTAX_CMD[${1%%.*}]}" ]]; then
		msg="${SYNTAX_CMD[${1%%.*}]}\n"
	fi

	local old_msg shelp
	for a in $2; do
		old_msg="$msg"

		if test "${a:0:4}" = "cmd:"; then
			test "$a" = "cmd:" && a="cmd:$1"
			test "${a:4}" = "*" && a='^[a-zA-Z0-9_]+$' || a="^${a:4:-2}"'\.[a-zA-Z0-9_]+$'
			for b in $keys; do
				grep -E "$a" >/dev/null <<< "$b" && msg="$msg\n$(basename $APP) ${SYNTAX_CMD[$b]}"
			done
		elif test "${a:0:5}" = "help:"; then
			test "$a" = "help:" && a="help:$1"
			test "${a:5}" = "*" && a='^[a-zA-Z0-9_]+$' || a="^${a:5:-2}"'\.[a-zA-Z0-9_\.]+$'

			shelp=""
			for b in `_sort ${!SYNTAX_HELP[@]}`; do
				if test "$b" = "$1"; then
					shelp="$shelp\n${SYNTAX_HELP[$b]}"
				elif grep -E "$a" >/dev/null <<< "$b"; then
					prefix=`sed -E 's/^[a-zA-Z0-9_]+\.//' <<< $b`
					shelp="$shelp\n"`printf "%12s: ${SYNTAX_HELP[$b]}" $prefix`
				fi
			done

			[[ ! -z "$shelp" && "$shelp" != "\n$APP_DESC" ]] && msg="$msg$shelp"
		fi

		test "$old_msg" != "$msg" && msg="$msg\n"
	done

	if ! test -z "$APP_PREFIX"; then
		echo -e "\nSYNTAX: $APP_PREFIX $(basename $APP) $msg" 1>&2
	else
		echo -e "\nSYNTAX: $(basename $APP) $msg" 1>&2
	fi

	local desc
	for a in APP_DESC APP_DESC_2 APP_DESC_3 APP_DESC_4; do
		test -z "${!a}" || desc="$desc${!a}\n\n"
	done
	echo -e "$desc" 1>&2

	exit 1
}

