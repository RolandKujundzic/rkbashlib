#!/bin/bash

#------------------------------------------------------------------------------
# Update/Create git project. Use subdir (js/, php/, ...) for other git projects.
#
# Example: git_checkout rk@git.tld:/path/to/repo test
# - if test/ exists: cd test; git pull; cd ..
# - if ../../test: ln -s ../../test; call again (goto 1st case)
# - else: git clone rk@git.tld:/path/to/repo test
#
# @param git url
# @param local directory
# @param after_checkout (e.g. "./run.sh build")
# @require abort
#------------------------------------------------------------------------------
function _git_checkout {
	local CURR="$PWD"

	if test -d "$2"
	then
		cd "$2"
		echo "git pull $2"
		git pull
		cd "$CURR"
	elif test -d "../../$2"
	then
		echo "link to ../../$2"
		ln -s "../../$2" "$2"
		cd "$CURR"
		_git_checkout "$1" "$2"
	else
		echo -e "git clone $2\nEnter password if necessary"
		git clone "$1" "$2"

		if ! test -d "$2/.git"; then
			_abort "git clone failed - no $2/.git directory"
		fi

		if ! test -z "$3"; then
			cd "$2"
			echo "run [$3] in $2"
			$3
			cd ..
		fi
	fi
}

