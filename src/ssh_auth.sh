#!/bin/bash

#------------------------------------------------------------------------------
# Create ssh key authentication for server $1 (rk@server.tld).
#------------------------------------------------------------------------------
function _ssh_auth {
	echo -e "\ncreate ssh keys for password less authentication"

	if ! test -f ~/.ssh/id_rsa.pub; then
		echo "creating local public+private key: ~/.ssh/id_rsa[.pub] - type 3x ENTER"
		ssh-keygen -t rsa
	fi

	local SSH_OK=`ssh -o 'PreferredAuthentications=publickey' $1 "echo" 2>&1`

	if ! test -z "$SSH_OK"; then
		echo "copy ~/.ssh/id_rsa.pub to $1"

		if test -d /Applications/iTunes.app; then
			./macos/ssh-copy-id.sh -i ~/.ssh/id_rsa.pub $1
		else
			# assume linux
			ssh-copy-id -i ~/.ssh/id_rsa.pub $1
		fi
	fi

	echo -e "done.\n\n"
}

