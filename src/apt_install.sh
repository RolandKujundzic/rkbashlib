#!/bin/bash

#--
# Install apt packages.
# @param $* (package list)
# @global LOG_NO_ECHO
# shellcheck disable=SC2048,SC2033
#--
function _apt_install {
	local curr_lne
	curr_lne=$LOG_NO_ECHO
	LOG_NO_ECHO=1

	_require_program apt
	_run_as_root 1
	_rkbash_dir

	for a in $*; do
		if test -d "$RKBASH_DIR/apt/$a"; then
			_msg "already installed, skip: apt -y install $a"
		else
			sudo apt -y install "$a" || _abort "apt -y install $a"
			_log "apt -y install $a" "apt/$a"
		fi
	done

	_rkbash_dir reset
	LOG_NO_ECHO=$curr_lne
}

