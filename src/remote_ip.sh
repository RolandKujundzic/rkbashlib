#!/bin/bash

#------------------------------------------------------------------------------
# Export remote ip adress. Shell browser lynx is required.
#
# @export REMOTE_IP REMOTE_IP_MSG
# @global REMOTE_IP_KEYSTROKE lynx keystroke file for IP_URL query
# @global REMOTE_IP_URL URL which will print your _SERVER[REMOTE_ADDR]
# @require _abort
#------------------------------------------------------------------------------
function _remote_ip {
	local HAS_LYNX=`which lynx`
	if test -z "$HAS_LYNX"; then
		_abort "lynx is not installed"
	fi

	if test -z "$REMOTE_IP_KEYSTROKE"; then
		_abort "missing REMOTE_IP_KEYSTROKE"
	fi

	if test -z "$REMOTE_IP_URL"; then
		_abort "missing REMOTE_IP_URL"
	fi

	local RIP_DIR=`dirname "$REMOTE_IP_KEYSTROKE"`

	if ! test -d "$RIP_DIR"; then
	       	mkdir -p "$RIP_DIR" || _abort "failed to create $RIP_DIR directory"
	fi

	if ! test -s "$REMOTE_IP_KEYSTROKE"; then
		echo -e "# $REMOTE_IP_URL\nkey q\nkey y" > "$REMOTE_IP_KEYSTROKE"
	fi

	REMOTE_IP_MSG=
	REMOTE_IP=

	if test -s "$REMOTE_IP_KEYSTROKE"; then
		REMOTE_IP=`lynx -cmd_script="$REMOTE_IP_KEYSTROKE" -dump "$REMOTE_IP_URL" | xargs`

		if ! test -z "$REMOTE_IP"; then
			REMOTE_IP_MSG="- ip $REMOTE_IP"
		fi
	fi
}

