#!/bin/bash

if [ "$(uname)" = "Darwin" ]; then

# enable alias expansion
shopt -s expand_aliases 

# osx has no realpath
alias realpath="python -c 'import os,sys;print os.path.realpath(sys.argv[1])'"


#------------------------------------------------------------------------------
# OSX has md5 instead of md5sum. Use md5sum function wrapper.
#
# @param file
#------------------------------------------------------------------------------
function md5sum {
	md5 -q "$1"
}


#------------------------------------------------------------------------------
# OSX /usr/bin/stat is incompatible with linux. Use stat function wrapper.
#
# @param -c
# @param -
# @require _abort 
#------------------------------------------------------------------------------
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
		fi
	else
		_abort "ToDo: stat $@"
	fi
}

fi

