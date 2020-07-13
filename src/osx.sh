#!/bin/bash

if [ "$(uname)" = "Darwin" ]; then

# enable alias expansion
shopt -s expand_aliases 

# osx has no md5sum
test -z "$(command -v md5sum)" && _abort "install brew (https://brew.sh/)"

# osx bash is outdated
test -f "/usr/local/bin/bash" || _abort "brew install bash"

# enable brew bash
[[ "$BASH_VERSION" =~ 5. ]] || _abort 'change shebang to: #!/usr/bin/env bash'  

# osx has no realpath
test -z "$(command -v realpath)" && _abort "brew install coreutils"

test "$(echo -e "a_c\naa_b" | sort | xargs)" != "aa_b a_c" && \
	_abort "UTF-8 sort is broken - fix /usr/share/locale/${LC_ALL}/LC_COLLATE"


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

