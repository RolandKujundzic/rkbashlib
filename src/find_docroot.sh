#!/bin/bash

#--
# Find document root of php project (realpath). Search for directory with 
# index.php and (settings.php file or data/ dir).
#
# @param string path e.g. $PWD (optional use $PWD as default)
# @param int don't abort if error (default = 0 = abort)
# @export DOCROOT
# @return bool (if $2=1)
#--
function _find_docroot {
	local dir base last_dir

	if test -n "$DOCROOT"; then
		DOCROOT=$(realpath "$DOCROOT")
		_msg "use existing DOCROOT=$DOCROOT"
		test -z "$DOCROOT" && { test -z "$2" && _abort "invalid DOCROOT" || return 1; }
		return 0
	fi

	if test -z "$1"; then
		dir=$(realpath "$PWD")
	else
		dir=$(realpath "$1")
	fi

	base=$(basename "$dir")
	test "$base" = "cms" && DOCROOT=$(dirname "$dir")

	if [[ -n "$DOCROOT" && -f "$DOCROOT/index.php" && (-f "$DOCROOT/settings.php" || -d "$DOCROOT/data") ]]; then
		_msg "use DOCROOT=$DOCROOT"
		return 0
	fi

	while [[ -d "$dir" && ! (-f "$dir/index.php" && (-f "$dir/settings.php" || -d "$dir/data")) ]]; do
		last_dir="$dir"
		dir=$(dirname "$dir")

		if test "$dir" = "$last_dir" || ! test -d "$dir"; then
			test -z "$2" && _abort "failed to find DOCROOT of [$1]" || return 1
		fi
	done

	if [[ -f "$dir/index.php" && (-f "$dir/settings.php" || -d "$dir/data") ]]; then
		DOCROOT="$dir"
	else
		test -z "$2" && _abort "failed to find DOCROOT of [$1]" || return 1
	fi

	return 0
}

