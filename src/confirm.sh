#!/bin/bash

#--
# Show "message  y [n]" (or $2 & 1: [y] n) and wait for key press. 
# Set CONFIRM=y if y key was pressed. Otherwise set CONFIRM=n if any other 
# key was pressed or 10 (3) sec expired. Use --q1=y and --q2=n call parameter to confirm
# question 1 and reject question 2. Set CONFIRM_COUNT= before _confirm if necessary.
# If AUTOCONFIRM is set (e.g. yyn) set CONFIRM=AUTOCONFIRM[0], shift AUTOCONFIRM left
# and return.
#
# @param string message
# @param 2^N flag 1=switch y and n (y = default, wait 3 sec) | 2=auto-confirm (y)
# @global AUTOCONFIRM --qN
# @export CONFIRM CONFIRM_TEXT
# shellcheck disable=SC2034
#--
function _confirm {
	CONFIRM=

	if ! test -z "$AUTOCONFIRM"; then
		CONFIRM="${AUTOCONFIRM:0:1}"
		echo "$1 <$CONFIRM>"
		AUTOCONFIRM="${AUTOCONFIRM:1}"
		return
	fi

	if test -z "$CONFIRM_COUNT"; then
		CONFIRM_COUNT=1
	else
		CONFIRM_COUNT=$((CONFIRM_COUNT + 1))
	fi

	local flag cckey default

	flag=$(($2 + 0))

	if test $((flag & 2)) = 2; then
		if test $((flag & 1)) = 1; then
			CONFIRM=n
		else
			CONFIRM=y
		fi

		return
	fi

	while read -r -d $'\0' 
	do
		cckey="--q$CONFIRM_COUNT"
		if test "$REPLY" = "$cckey=y"; then
			echo "found $cckey=y, accept: $1" 
			CONFIRM=y
		elif test "$REPLY" = "$cckey=n"; then
			echo "found $cckey=n, reject: $1" 
			CONFIRM=n
		fi
	done < /proc/$$/cmdline

	if ! test -z "$CONFIRM"; then
		# found -y or -n parameter
		CONFIRM_TEXT="$CONFIRM"
		return
	fi

	if test $((flag & 1)) -ne 1; then
		default=n
		echo -n "$1  y [n]  "
		read -r -n1 -t 10 CONFIRM
		echo
	else
		default=y
		echo -n "$1  [y] n  "
		read -r -n1 -t 3 CONFIRM
		echo
	fi

	if test -z "$CONFIRM"; then
		CONFIRM="$default"
	fi

	CONFIRM_TEXT="$CONFIRM"

	if test "$CONFIRM" != "y"; then
		CONFIRM=n
  fi
}

