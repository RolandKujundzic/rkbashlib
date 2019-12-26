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
# @param local directory (optional, default = basename $1 without .git)
# @param after_checkout (e.g. "./run.sh build")
# @global CONFIRM_CHECKOUT (if =1 use positive confirm if does not exist) GIT_PARAMETER
# @require _abort _confirm _cd _ln
#--
function _git_checkout {
	local CURR="$PWD"
	local GIT_DIR="${2:-`basename "$1" | sed -E 's/\.git$//'`}"

	if test -d "$GIT_DIR"; then
		_confirm "Update $GIT_DIR (git pull)?" 1
	elif ! test -z "$CONFIRM_CHECKOUT"; then
		_confirm "Checkout $1 to $GIT_DIR (git clone)?" 1
	fi

	if test "$CONFIRM" = "n"; then
		echo "Skip $1"
		return
	fi

	if test -d "$GIT_DIR"; then
		_cd "$GIT_DIR"
		echo "git pull $GIT_DIR"
		git pull
		test -s .gitmodules && git submodule update --init --recursive --remote
		test -s .gitmodules && git submodule foreach "(git checkout master; git pull)"
		_cd "$CURR"
	elif test -d "../../$GIT_DIR/.git" && ! test -L "../../$GIT_DIR"; then
		_ln "../../$GIT_DIR" "$GIT_DIR"
		_git_checkout "$1" "$GIT_DIR"
	else
		echo -e "git clone $GIT_PARAMETER '$1' '$GIT_DIR'\nEnter password if necessary"
		git clone $GIT_PARAMETER "$1" "$GIT_DIR"

		if ! test -d "$GIT_DIR/.git"; then
			_abort "git clone failed - no $GIT_DIR/.git directory"
		fi

		if test -s "$GIT_DIR/.gitmodules"; then
			_cd "$GIT_DIR"
			test -s .gitmodules && git submodule update --init --recursive --remote
			test -s .gitmodules && git submodule foreach "(git checkout master; git pull)"
			_cd ..
		fi

		if ! test -z "$3"; then
			_cd "$GIT_DIR"
			echo "run [$3] in $GIT_DIR"
			$3
			_cd ..
		fi
	fi

	GIT_PARAMETER=
}

