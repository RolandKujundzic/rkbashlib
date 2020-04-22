#!/bin/bash

#--
# Create vhost link to $2. Create /website/... and docroot.
# Add $1 domain to /etc/hosts (if *.xx). 
#
# @param domain
# @param docroot
#--
function _apache2_vhost {
	if ! test -d "$2"; then
		_confirm "Create docroot '$2'?" 1
		test "$CONFIRM" = "y" && _mkdir "$2"
	fi

	_split '.' "$1" >/dev/null

	local a

	if test "${#_SPLIT[@]}" -eq 2; then
		a="/website/${_SPLIT[0]}"'_'"${_SPLIT[1]}"
		_mkdir "$a"
		_cd "$a"
		_ln "$2" '_'
	else
		a="/website/${_SPLIT[1]}"'_'"${_SPLIT[2]}"
		_mkdir "$a"
		_cd "$a"
		_ln "$2" "${_SPLIT[0]}"
	fi

	local IS_XX=`echo "$1" | grep -E '\.xx$'`
	if ! test -z "$IS_XX"; then
		_msg "Add $1 domain to /etc/hosts"
		_append_txt /etc/hosts "127.0.0.1 $1"
	fi
}

