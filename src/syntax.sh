#!/bin/bash

#------------------------------------------------------------------------------
# Abort with SYNTAX: message.
#
# @global APP, APP_DESC
#------------------------------------------------------------------------------
function _syntax {
	echo -e "\nSYNTAX: $APP $1\n\n" 1>&2

	if ! test -z "$APP_DESC"; then
		echo -e "$APP_DESC\n\n" 1>&2
	fi

	exit 1
}

