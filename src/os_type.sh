#!/bin/bash

#--
# Return linux, macos, cygwin.
#
# @print string (abort if set and os_type != $1)
#--
function _os_type {
	local os=

	if [ "$(uname)" = "Darwin" ]; then
		os="macos"        
	elif [ "$OSTYPE" = "linux-gnu" ]; then
		os="linux"
	elif [ $(expr substr $(uname -s) 1 5) = "Linux" ]; then
		os="linux"
	elif [ $(expr substr $(uname -s) 1 5) = "MINGW" ]; then
		os="cygwin"
	fi

	if ! test -z "$1" && test "$1" != "$os"; then
		_abort "$os required (this is $os)"
	fi

	echo $os
}
