#!/bin/bash

#--
# Print script header header to file.
#
# @param filename
#--
function _rks_header {
	local copyright=`date +"%Y"`

	if test -f ".gitignore"; then
		copyright=`git log --diff-filter=A -- .gitignore | grep 'Date:' | sed -E 's/.+ ([0-9]+) \+[0-9]+/\1/'`" - $copyright"
	fi

	echo -e "#!/bin/bash
#
# Copyright (c) $copyright Roland Kujundzic <roland@kujundzic.de>
#
" > "$1"
	# . /usr/local/lib/rkscript.sh || { echo -e "\nERROR: . /usr/local/lib/rkscript.sh\n"; exit 1; }'
}

