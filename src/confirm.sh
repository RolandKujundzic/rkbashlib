#!/bin/bash

#--
# Show "message  Press y or n  " and wait for key press. 
# Set CONFIRM=y if y key was pressed. Otherwise set CONFIRM=n if any other 
# key was pressed or 10 sec expired. Use --q1=y and --q2=n call parameter to confirm
# question 1 and reject question 2. Set CONFIRM_COUNT= before _confirm if necessary.
#
# @param string message
# @param 2^N flag 1=switch y and n (y = default, wait 3 sec) | 2=auto-confirm (y)
# @export CONFIRM CONFIRM_TEXT
#--
function _confirm {
	CONFIRM=

	if test -z "$CONFIRM_COUNT"; then
		CONFIRM_COUNT=1
	else
		CONFIRM_COUNT=$((CONFIRM_COUNT + 1))
	fi

	local FLAG=$(($2 + 0))

	if test $((FLAG & 2)) = 2; then
		if test $((FLAG & 1)) = 1; then
			CONFIRM=n
		else
			CONFIRM=y
		fi

		return
	fi

	while read -d $'\0' 
	do
		local CCKEY="--q$CONFIRM_COUNT"
		if test "$REPLY" = "$CCKEY=y"; then
			echo "found $CCKEY=y, accept: $1" 
			CONFIRM=y
		elif test "$REPLY" = "$CCKEY=n"; then
			echo "found $CCKEY=n, reject: $1" 
			CONFIRM=n
		fi
	done < /proc/$$/cmdline

	if ! test -z "$CONFIRM"; then
		# found -y or -n parameter
		CONFIRM_TEXT="$CONFIRM"
		return
	fi

	local DEFAULT=

	if test $((FLAG & 1)) -ne 1; then
		DEFAULT=n
		echo -n "$1  y [n]  "
		read -n1 -t 10 CONFIRM
		echo
	else
		DEFAULT=y
		echo -n "$1  [y] n  "
		read -n1 -t 3 CONFIRM
		echo
	fi

	if test -z "$CONFIRM"; then
		CONFIRM=$DEFAULT
	fi

	CONFIRM_TEXT="$CONFIRM"

	if test "$CONFIRM" != "y"; then
		CONFIRM=n
  fi
}

