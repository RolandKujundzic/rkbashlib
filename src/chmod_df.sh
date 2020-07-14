#!/bin/bash

#--
# Change file+directory privileges recursive.
#
# @param path/to/entry
# @param file privileges (default = 644)
# @param dir privileges (default = 755)
# @param main dir privileges (default = dir privleges)
#--
function _chmod_df {
	local chmod_path fpriv dpriv mdpriv
	chmod_path="$1"
	fpriv="$2"
	dpriv="$3"
	mdpriv="$4"

	if [[ ! -d "$chmod_path" && ! -f "$chmod_path" ]]; then
		_abort "no such directory or file: [$chmod_path]"
	fi

	test -z "$fpriv" && fpriv=644
	test -z "$dpriv" && dpriv=755

	_file_priv "$chmod_path" $fpriv
	_dir_priv "$chmod_path" $dpriv

	if [[ -n "$mdpriv" && "$mdpriv" != "$dpriv" ]]; then
		echo "chmod $mdpriv '$chmod_path'"
		chmod "$mdpriv" "$chmod_path" || _abort "chmod $mdpriv '$chmod_path'"
	fi
}

