#!/bin/bash

#--
# Abort if file does not exists or owner or privileges don't match.
#
# @param path
# @param owner[:group] (optional)
# @param privileges (optional, e.g. 600)
# @require _abort _require_owner _require_priv
#--
function _require_file {
	test -f "$1" || _abort "no such file '$1'"

	if ! test -z "$2"; then
		_require_owner "$1" "$2"
	fi

	if ! test -z "$3"; then
		_require_priv "$1" "$3"
	fi
}

