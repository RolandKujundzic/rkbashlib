#!/bin/bash

#--
# Update/Create git project. Use subdir (js/, php/, ...) for other git projects.
# For git parameter (e.g. [-b master --single-branch]) use global variable GIT_PARAMETER.
# Use ARG[docroot] to checkout into ARG[docroot] and link.
#
# Example: git_checkout rk@git.tld:/path/to/repo test
# - if test/ exists: cd test; git pull; cd ..
# - if ../../test: ln -s ../../test; call again (goto 1st case)
# - else: git clone rk@git.tld:/path/to/repo test
#
# @param git url
# @param local directory (optional, default = basename $1 without .git)
# @param after_checkout (e.g. "./run.sh build")
# @global ARG[docroot] CONFIRM_CHECKOUT (if =1 use positive confirm if does not exist) GIT_PARAMETER
# shellcheck disable=SC2086
#--
function _git_checkout {
	local curr git_dir lnk_dir
	curr="$PWD"
	git_dir="${2:-$(basename "$1" | sed -E 's/\.git$//')}"

	if test -n "${ARG[docroot]}"; then
		lnk_dir="$2"
		git_dir="${ARG[docroot]}"

		if [[ -L "$lnk_dir" && "$(realpath "$lnk_dir")" = "$(realpath "$git_dir")" ]]; then
			_confirm "Update $git_dir (git pull)?" 1
		elif [[ ! -L "$lnk_dir" && ! -d "$lnk_dir" && ! -d "$git_dir" ]]; then
			_confirm "Checkout $1 to $git_dir (git clone)?" 1
		elif test -d "$git_dir"; then
			_abort "link to $git_dir missing ($lnk_dir)"
		elif test -L "$lnk_dir"; then
			_abort "$lnk_dir does not link to $git_dir"
		elif test -d "$lnk_dir"; then
			_abort "directory $lnk_dir already exists"
		fi
	elif test -d "$git_dir"; then
		_confirm "Update $git_dir (git pull)?" 1
	elif test -n "$CONFIRM_CHECKOUT"; then
		_confirm "Checkout $1 to $git_dir (git clone)?" 1
	fi

	if test "$CONFIRM" = "n"; then
		echo "Skip $1"
		return
	fi

	if test -d "$git_dir"; then
		_cd "$git_dir"
		echo "git pull $git_dir"
		git pull
		_git_submodule
		_cd "$curr"
	elif test -d "../../$git_dir/.git" && ! test -L "../../$git_dir"; then
		_ln "../../$git_dir" "$git_dir"
		_git_checkout "$1" "$git_dir"
	else
		echo -e "git clone $GIT_PARAMETER '$1' '$git_dir'\nEnter password if necessary"
		git clone $GIT_PARAMETER "$1" "$git_dir"

		if ! test -d "$git_dir/.git"; then
			_abort "git clone failed - no $git_dir/.git directory"
		fi

		if test -s "$git_dir/.gitmodules"; then
			_cd "$git_dir"
			_git_submodule
			_cd ..
		fi

		if test -n "$3"; then
			_cd "$git_dir"
			echo "run [$3] in $git_dir"
			$3
			_cd ..
		fi
	fi

	[[ -n "$lnk_dir" && ! -L "$lnk_dir" ]] && _ln "$git_dir" "$lnk_dir"

	GIT_PARAMETER=
}

