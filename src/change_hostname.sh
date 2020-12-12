#!/bin/bash

#--
# Change hostname if hostname != $1.
#
# @param name.domain.tld
# shellcheck disable=SC1001
#--
function _change_hostname {
	local hname ip hs hd

	[[ -z "$1" || ! "$1" =~ ^[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-]+$ ]] && \
		_abort "invalid hostname '$1' use name.domain.tld"

	_run_as_root

	hname=$(hostname)

	_require_program hostname
	_require_program hostnamectl

	if [[ "$1" != "$hname" ]]; then
		_msg "change hostname '$hname' to '$1'"
		hostnamectl set-hostname "$1" || _abort "hostnamectl set-hostname '$1'"
	fi

	ip=$(hostname -i)
	hs=$(hostname -s)
	hd=$(hostname -d)

	_require_file /etc/hosts

	if test -z "$(grep "$ip $hs.$hd $hs" /etc/hosts)"; then
		_msg "append '$ip $hs.$hd $hs' to /etc/hosts"
		echo "$ip $hs.$hd $hs" >> /etc/hosts
	fi
}

