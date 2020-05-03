#!/bin/bash

#--
# Create ssh key authentication for server $1 (rk@server.tld).
#--
function _ssh_auth {
	echo "create ssh keys for password less authentication"

	if ! test -f ~/.ssh/id_rsa.pub; then
		echo "creating local public+private key: ~/.ssh/id_rsa[.pub] - type 3x ENTER"
		ssh-keygen -t rsa
	fi

	local ssh_ok
	ssh_ok=$(ssh -o 'PreferredAuthentications=publickey' $1 "echo" 2>&1)

	if ! test -z "$ssh_ok"; then
		echo "copy ~/.ssh/id_rsa.pub to $1"

		if test -d /Applications/iTunes.app; then
			./macos/ssh-copy-id.sh -i ~/.ssh/id_rsa.pub $1
		else
			# assume linux
			ssh-copy-id -i ~/.ssh/id_rsa.pub $1
		fi
	fi
}

