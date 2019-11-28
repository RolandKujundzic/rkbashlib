#!/bin/bash

#--
# Update/Create git project. Use subdir (js/, php/, ...) for other git projects.
# For git parameter (e.g. [-b master --single-branch]) use global variable GIT_PARAMETER.
#
# Example: git_checkout rk@git.tld:/path/to/repo test
# - if test/ exists: cd test; git pull; cd ..
# - if ../../test: ln -s ../../test; call again (goto 1st case)
# - else: git clone rk@git.tld:/path/to/repo test
#
# @param git url
# @param local directory
# @param after_checkout (e.g. "./run.sh build")
# @global CONFIRM_CHECKOUT (if =1 use positive confirm if does not exist) GIT_PARAMETER
# @require _abort _confirm _cd _ln
#--
function _git_checkout {
	local CURR="$PWD"

	if test -d "$2"; then
		_confirm "Update $2 (git pull)?" 1
	elif ! test -z "$CONFIRM_CHECKOUT"; then
		_confirm "Checkout $1 to $2 (git clone)?" 1
	fi

	if test "$CONFIRM" = "n"; then
		echo "Skip $1"
		return
	fi

	if test -d "$2"; then
		_cd "$2"
		echo "git pull $2"
		git pull
		test -s .gitmodules && git submodule update --init --recursive --remote
		test -s .gitmodules && git submodule foreach "(git checkout master; git pull)"
		_cd "$CURR"
	elif test -d "../../$2" && ! test -L "../../$2"; then
		_ln "../../$2" "$2"
		_git_checkout "$1" "$2"
	else
		echo -e "git clone $GIT_PARAMETER '$1' '$2'\nEnter password if necessary"
		git clone $GIT_PARAMETER "$1" "$2"

		if ! test -d "$2/.git"; then
			_abort "git clone failed - no $2/.git directory"
		fi

		if test -s "$2/.gitmodules"; then
			_cd "$2"
			test -s .gitmodules && git submodule update --init --recursive --remote
			test -s .gitmodules && git submodule foreach "(git checkout master; git pull)"
			_cd ..
		fi

		if ! test -z "$3"; then
			_cd "$2"
			echo "run [$3] in $2"
			$3
			_cd ..
		fi
	fi

	GIT_PARAMETER=
}

