#!/bin/bash

#--
# Print script header header to file. Flag:
#
# 1 = load /usr/local/lib/rkbash.lib.sh
#
# @global RKS_HEADER (optional instead of flag) RKS_HEADER_SCHECK (shellcheck ...)
# @param filename
# @param int flag (2^n)
#--
function _rks_header {
	local flag header copyright
	copyright=$(date +"%Y")
	flag=$(($2 + 0))

	[ -z "${RKS_HEADER+x}" ] || flag=$((RKS_HEADER + 0))

	if test -f ".gitignore"; then
		copyright=$(git log --diff-filter=A -- .gitignore | grep 'Date:' | sed -E 's/.+ ([0-9]+) \+[0-9]+/\1/')" - $copyright"
	fi

	test $((flag & 1)) = 1 && \
		header='. /usr/local/lib/rkbash.lib.sh || { echo -e "\nERROR: . /usr/local/lib/rkbash.lib.sh\n"; exit 1; }'

	printf '\x23!/usr/bin/env bash\n\x23\n\x23 Copyright (c) %s Roland Kujundzic <roland@kujundzic.de>\n\x23\n\x23 %s\n\x23\n\n' \
		"$copyright" "$RKS_HEADER_SCHECK" > "$1"
	test -z "$header" || echo "$header" >> "$1"
}

