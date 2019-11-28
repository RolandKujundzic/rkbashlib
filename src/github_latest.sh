#!/bin/bash

declare -A GITHUB_LATEST
declare -A GITHUB_IS_LATEST

#--
# Export GITHUB_[IS_]LATEST[$2].
#
# @export $GITHUB_LATEST[$1] = NN.NN and GITHUB_IS_LATEST[$1]=1|''
# @param $1 user/project (latest github url = https://github.com/[user/project]/releases/latest)
# @param $2 app
#--
function _github_latest {
	local VNUM=`$2 --version 2>/dev/null | sed -E 's/.+ version ([0-9]+\.[0-9]+)\.?([0-9]*).+/\1\2/'`
	local REDIR=`curl -Ls -o /dev/null -w %{url_effective} "https://github.com/$1/releases/latest"`
	local LATEST=`basename "$REDIR" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+)\.?([0-9]*).*/\1\2/'`

	if ! test -z "$LATEST"; then
		GITHUB_LATEST[$2]=`basename "$REDIR"`
		GITHUB_IS_LATEST[$2]=''

		if ! test -z "$VNUM" && test `echo "$VNUM >= $LATEST" | bc -l` == 1; then
			GITHUB_IS_LATEST[$2]=1
		fi
	fi
}

