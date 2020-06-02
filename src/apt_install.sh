#!/bin/bash

#--
# Install apt packages.
# @param $* (package list)
# @global LOG_NO_ECHO
# shellcheck disable=SC2048
#--
function _apt_install {
	local curr_lne
	curr_lne=$LOG_NO_ECHO
	LOG_NO_ECHO=1

	_run_as_root 1

	test "$RKBASH_DIR" = "$HOME/.rkbash/$$" && RKBASH_DIR="$HOME/.rkbash"

	for a in $*; do
		if test -d "$RKBASH_DIR/apt/$a"; then
			echo "already installed, skip: apt -y install $a"
		else
			sudo apt -y install "$a" || _abort "apt -y install $a"
			_log "apt -y install $a" "apt/$a"
		fi
	done

	test "$RKBASH_DIR" = "$HOME/.rkbash" && RKBASH_DIR="$HOME/.rkbash/$$"

	LOG_NO_ECHO=$curr_lne
}

