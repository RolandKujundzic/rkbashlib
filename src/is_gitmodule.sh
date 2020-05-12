#!/bin/bash

#--
# Print module name if $module is git module.
#
# @param module name
#--
function _is_gitmodule {

	if test -z "$1" || ! test -s ".gitmodule"; then
		return
	fi

	grep -E "\[submodule \".*$1\"\]" .gitmodules | sed -E "s/\[submodule \"(.*$1)\"\]/\1/"
}

