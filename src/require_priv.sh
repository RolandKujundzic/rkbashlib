#!/bin/bash

#--
# Abort if file or directory privileges don't match.
#
# @param path
# @param privileges (e.g. 600)
#--
function _require_priv {
	test -z "$2" && _abort "empty privileges"
	local priv
	priv=$(stat -c '%a' "$1" 2>/dev/null)
	test -z "$priv" && _abort "stat -c '%a' '$1'"
	test "$2" = "$priv" || _abort "invalid privileges [$priv] - chmod -R $2 '$1'"
}

