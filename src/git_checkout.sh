#!/bin/bash

#------------------------------------------------------------------------------
# Update/Create git project. Use subdir (js/, php/, ...) for other git projects.
#
# Example: git_checkout rk@git.tld:/path/to/repo test
# - if test/ exists: cd test; git pull test; cd ..
# - if ../../test: ln -s ../../test; call again (goto 1st case)
# - else: git clone rk@git.tld:/path/to/repo
#------------------------------------------------------------------------------
function _git_checkout {
	local CURR="$PWD"

	if test -d "$2"
	then
		cd "$2"
		echo -e "\ngit pull $2"
		git pull
		cd "$CURR"
	elif test -d "../../$2"
	then
		echo -e "\nlink to ../../$2"
		ln -s "../../$2" "$2"
		cd "$CURR"
		_git_checkout "$1" "$2"
	else
		echo -e "\ngit clone $2"
		git clone "$1/$2.git"
	fi

	echo -e "done.\n\n"
}

