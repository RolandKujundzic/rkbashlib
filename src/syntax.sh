#!/bin/bash

#--
# Abort with SYNTAX: message.
# Usually APP=$0
#
# @global APP, APP_DESC, $APP_PREFIX
# @param message
#--
function _syntax {
	if ! test -z "$APP_PREFIX"; then
		echo -e "\nSYNTAX: $APP_PREFIX $APP $1\n" 1>&2
	else
		echo -e "\nSYNTAX: $APP $1\n" 1>&2
	fi

	if ! test -z "$APP_DESC"; then
		echo -e "$APP_DESC\n\n" 1>&2
	else
		echo 1>&2
	fi

	exit 1
}

