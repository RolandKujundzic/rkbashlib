#!/bin/bash

#------------------------------------------------------------------------------
# Abort if directory does not exists or owner or privileges don't match.
#
# @param path
# @param owner[:group] (optional)
# @param privileges (optional, e.g. 600)
# @require _abort _require_priv _require_owner
#------------------------------------------------------------------------------
function _require_dir {
	test -d "$1" || _abort "no such directory '$1'"

	if ! test -z "$2"; then
		_require_owner "$1" "$2"
	fi

	if ! test -z "$3"; then
		_require_priv "$1" "$3"
	fi
}

