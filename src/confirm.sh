#!/bin/bash

#------------------------------------------------------------------------------
# Show "message  Press y or n  " and wait for key press. 
# Set CONFIRM=y if y key was pressed. Otherwise set CONFIRM=n if any other 
# key was pressed or 10 sec expired.
#
# @param string message
# @export CONFIRM CONFIRM_TEXT
#------------------------------------------------------------------------------
function _confirm {
	CONFIRM=n

	echo -n "$1  y [n]  "
	read -n1 -t 10 CONFIRM
	echo

	CONFIRM_TEXT="$CONFIRM"

	if test "$CONFIRM" != "y"; then
		CONFIRM=n
  fi
}

