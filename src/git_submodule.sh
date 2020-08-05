#!/bin/bash

#--
# Update|Checkout submodule if .gitmodules exists
#--
function _git_submodule {
	test -s .gitmodules || return

	git submodule sync	# copy changes from .gitmodules to .git/config
	git submodule update --init --recursive --remote
	git submodule foreach "(git checkout master; git pull)"
}

