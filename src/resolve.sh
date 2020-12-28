#!/bin/bash

#--
# @example _resolv domain2ip some.domain.tld
# @example _resolv ip2domain 8.8.8.8
#--
function _resolve {
	local res

	if test "$1" = 'domain2ip'; then
		test -z "$2" && _syntax '_resolve domain2ip some.domain.tld'
		res=$(host "$2" | grep "$2 has address" | sed -E 's/.+has address //')
	elif test "$1" = 'ip2domain'; then
		test -z "$2" && _syntax '_resolve ip2domain 8.8.8.8'
		res=$(nslookup "$2" | grep 'name = ' | sed -E 's/.+name = (.+)\./\1/')
	else
		_syntax '_resolv domain2ip|ip2domain'
	fi

	test -z "$res" && _abort "_resolv '$1' '$2' failed"
	echo -n "$res"
}

