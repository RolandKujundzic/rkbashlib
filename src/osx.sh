#!/bin/bash

if [ "$(uname)" = "Darwin" ]; then

# enable alias expansion
shopt -s expand_aliases 

# osx has no md5sum
test -z "$(which md5sum)" && _abort "install brew (https://brew.sh/)"

# osx has no realpath
test -z "$(which realpath)" && _abort "brew install coreutils"


#--
# OSX /usr/bin/stat is incompatible with linux. Use stat function wrapper.
#
# @param -c
# @param -
# shellcheck disable=SC2012
#--
function stat {
	if test "$1" = "-c"; then
		if test "$2" = "%Y"; then
			/usr/bin/stat -f %m "$3"
			return
		elif test "$2" = "%U"; then
			ls -la "$3" | awk '{print $3}'
		elif test "$2" = "%G"; then
			ls -la "$3" | awk '{print $3}'
		elif test "$2" = "%a"; then
			/usr/bin/stat -f %A "$3"
		else
			_abort "ToDo: stat $*"
		fi
	else
		_abort "ToDo: stat $*"
	fi
}

fi

