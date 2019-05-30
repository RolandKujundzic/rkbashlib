#!/bin/bash

#------------------------------------------------------------------------------
# Show "message  Press y or n  " and wait for key press. 
# Set CONFIRM=y if y key was pressed. Otherwise set CONFIRM=n if any other 
# key was pressed or 10 sec expired. Use --q1=y and --q2=n call parameter to confirm
# question 1 and reject question 2.
#
# @param string message
# @export CONFIRM CONFIRM_TEXT
#------------------------------------------------------------------------------
function _confirm {
	CONFIRM=

	if test -z "$CONFIRM_COUNT"; then
		CONFIRM_COUNT=1
	fi

	CONFIRM_COUNT=$((CONFIRM_COUNT + 1))

  while read -d $'\0' 
  do
    if test "$REPLY" = "--$CONFIRM_COUNT=y"; then
			echo "found --$CONFIRM_COUNT=y, accept: $1" 
			CONFIRM=y
		elif test "$REPLY" = "-n"; then
			echo "found --$CONFIRM_COUNT=n, reject: $1" 
      CONFIRM=n
    fi
  done < /proc/$$/cmdline

	if ! test -z "$CONFIRM"; then
		# found -y or -n parameter
		CONFIRM_TEXT="$CONFIRM"
		return
	fi

	CONFIRM=n

	echo -n "$1  y [n]  "
	read -n1 -t 10 CONFIRM
	echo

	CONFIRM_TEXT="$CONFIRM"

	if test "$CONFIRM" != "y"; then
		CONFIRM=n
  fi
}

