#!/bin/bash

#--
# Wrapper to scp. Check md5sum first - don't copy if md5sum is same.
# @param source
# @param target
# shellcheck disable=SC2029
#--
function _scp {
	local user host path md5 md5remote

	if [[ "$1" =~ ^(.+)@(.+):(/.+) ]]; then
		md5=$(_md5 "$2")
	elif [[ "$2" =~ ^(.+)@(.+):(/.+) ]]; then
		md5=$(_md5 "$1")
	else
		_abort "neither [$1] or [$2] are remote"
	fi

	user="${BASH_REMATCH[1]}"
	host="${BASH_REMATCH[2]}"
	path="${BASH_REMATCH[3]}"

	md5remote=$(ssh "$user@$host" "md5sum '$path'" 2>/dev/null | awk '{print $1}')
	
	if test "$md5" = "$md5remote"; then
		echo "$path at $host has not changed" 
	else
		echo "scp $1 $2"
		scp "$1" "$2" >/dev/null || _abort "_scp $1 $2" 
	fi
}

