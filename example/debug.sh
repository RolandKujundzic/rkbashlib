#!/bin/bash

# toggle DEBUG MODE: on=[set -x]
set -x

function _execute {
	echo "Parameter: ${@}"

	printf "execute: [%s]\n" "$1"

	if [ $(($2 + 0)) -eq 1 ]; then
		## working but dangerous
		eval "$1"
	else
		$1
	fi
}

_execute "echo 'Hello'"
_execute "echo 'Be verbose'" 1
_execute "cp 'no such file.txt' 'no such directory/new filename.txt'" 1
