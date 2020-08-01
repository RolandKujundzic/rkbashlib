#!/bin/bash

#--
# Change RKBASH_DIR to ~/.rkbash/$1 if directory is default. 
# Use $1 = reset to change to ~/.rkbash/$$.
# 
# @param optional ~/.rkbash subdirectory or reset
# @export RKBASH_DIR
#--
function _rkbash_dir {
	if [[ "$RKBASH_DIR" = "$HOME/.rkbash" && "$1" = 'reset' ]]; then
		RKBASH_DIR="$HOME/.rkbash/$$"
		return
	fi

	if [[ "$RKBASH_DIR" != "$HOME/.rkbash/$$" ]]; then
		:
	elif test -z "$1"; then
		RKBASH_DIR="$HOME/.rkbash"
	elif [[ "$1" != 'reset' ]]; then
		RKBASH_DIR="$HOME/.rkbash/$1"
		_mkdir "$RKBASH_DIR"
	fi
}
	
