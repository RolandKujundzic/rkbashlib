#!/bin/bash

#--
# Print script header header to file. Flag:
#
# 1 = load /usr/local/lib/rkscript.sh
#
# @global RKS_HEADER (optional instead of flag)
# @param filename
# @param int flag (2^n)
#--
function _rks_header {
	local copyright=`date +"%Y"`
	local flag=$(($2 + 0))
	local header

	[ -z ${RKS_HEADER+x} ] || flag=$(($RKS_HEADER + 0))

	if test -f ".gitignore"; then
		copyright=`git log --diff-filter=A -- .gitignore | grep 'Date:' | sed -E 's/.+ ([0-9]+) \+[0-9]+/\1/'`" - $copyright"
	fi

	test $((flag & 1)) = 1 && \
		header="\n\n. /usr/local/lib/rkscript.sh || { echo -e "'"\\nERROR: . /usr/local/lib/rkscript.sh\\n"; exit 1; }'

	echo -e "#!/bin/bash
#
# Copyright (c) $copyright Roland Kujundzic <roland@kujundzic.de>
#$header" > "$1"
}

