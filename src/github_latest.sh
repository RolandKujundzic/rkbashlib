#!/bin/bash

declare -A GITHUB_LATEST
declare -A GITHUB_IS_LATEST

#--
# Export GITHUB_[IS_]LATEST[$2].
#
# @export $GITHUB_LATEST[$1] = NN.NN and GITHUB_IS_LATEST[$1]=1|''
# @param $1 user/project (latest github url = https://github.com/[user/project]/releases/latest)
# @param $2 app
# shellcheck disable=SC2034
#--
function _github_latest {
	local vnum redir latest
	vnum=$($2 --version 2>/dev/null | sed -E 's/.+ version ([0-9]+\.[0-9]+)\.?([0-9]*).+/\1\2/')
	redir=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")
	latest=$(basename "$redir" | sed -E 's/[^0-9]*([0-9]+\.[0-9]+)\.?([0-9]*).*/\1\2/')

	if ! test -z "$latest"; then
		GITHUB_LATEST[$2]=$(basename "$redir")
		GITHUB_IS_LATEST[$2]=''

		if ! test -z "$vnum" && test "$(echo "$vnum >= $latest" | bc -l)" == 1; then
			GITHUB_IS_LATEST[$2]=1
		fi
	fi
}

